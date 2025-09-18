// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/ZSnailMath.sol";
import "../libraries/ZSnailSecurity.sol";
import "../libraries/ZSnailCrypto.sol";

/**
 * @title ZSnailGovernance
 * @dev Custom governance contract for ZSnail L2 blockchain DAO
 * @notice Manages protocol parameters, upgrades, and community decisions
 */
contract ZSnailGovernance {
    using ZSnailMath for uint256;
    using ZSnailSecurity for bytes32;
    using ZSnailCrypto for bytes32[];
    
    // Governance token
    string public constant TOKEN_NAME = "ZSnail Governance Token";
    string public constant TOKEN_SYMBOL = "ZGT";
    uint8 public constant DECIMALS = 18;
    uint256 public totalSupply;
    
    // Governance parameters
    uint256 public constant VOTING_DELAY = 7 days;
    uint256 public constant VOTING_PERIOD = 14 days;
    uint256 public constant EXECUTION_DELAY = 2 days;
    uint256 public constant PROPOSAL_THRESHOLD = 1000 * 10**DECIMALS; // 1000 ZGT
    uint256 public constant QUORUM_PERCENTAGE = 4; // 4% of total supply
    
    // Proposal states
    enum ProposalState {
        Pending,
        Active,
        Canceled,
        Defeated,
        Succeeded,
        Queued,
        Expired,
        Executed
    }
    
    // Proposal structure
    struct Proposal {
        uint256 id;
        address proposer;
        string title;
        string description;
        address[] targets;
        uint256[] values;
        string[] signatures;
        bytes[] calldatas;
        uint256 startBlock;
        uint256 endBlock;
        uint256 forVotes;
        uint256 againstVotes;
        uint256 abstainVotes;
        bool canceled;
        bool executed;
        bytes32 eta;
        mapping(address => Receipt) receipts;
    }
    
    // Vote receipt
    struct Receipt {
        bool hasVoted;
        uint8 support; // 0=against, 1=for, 2=abstain
        uint256 votes;
    }
    
    // Token balances and voting power
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    mapping(address => uint256) public votingPower;
    mapping(address => uint256) public votingPowerSnapshots;
    
    // Proposals
    mapping(uint256 => Proposal) public proposals;
    uint256 public proposalCount;
    
    // Timelock
    mapping(bytes32 => bool) public queuedTransactions;
    
    // Admin roles
    address public admin;
    address public pendingAdmin;
    address public guardian;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event ProposalCreated(
        uint256 id,
        address proposer,
        address[] targets,
        uint256[] values,
        string[] signatures,
        bytes[] calldatas,
        uint256 startBlock,
        uint256 endBlock,
        string description
    );
    event VoteCast(address indexed voter, uint256 proposalId, uint8 support, uint256 weight);
    event ProposalCanceled(uint256 id);
    event ProposalQueued(uint256 id, uint256 eta);
    event ProposalExecuted(uint256 id);
    event NewAdmin(address oldAdmin, address newAdmin);
    event NewPendingAdmin(address oldPendingAdmin, address newPendingAdmin);
    event NewGuardian(address oldGuardian, address newGuardian);
    
    modifier onlyAdmin() {
        require(msg.sender == admin, "ZSnailGovernance: admin only");
        _;
    }
    
    modifier onlyGuardian() {
        require(msg.sender == guardian, "ZSnailGovernance: guardian only");
        _;
    }
    
    modifier onlyGovernance() {
        require(msg.sender == address(this), "ZSnailGovernance: governance only");
        _;
    }
    
    constructor(
        address _admin,
        address _guardian,
        uint256 _initialSupply
    ) {
        admin = _admin;
        guardian = _guardian;
        totalSupply = _initialSupply;
        _balances[_admin] = _initialSupply;
        votingPower[_admin] = _initialSupply;
        
        emit Transfer(address(0), _admin, _initialSupply);
    }
    
    // ERC20 Functions
    function name() public pure returns (string memory) {
        return TOKEN_NAME;
    }
    
    function symbol() public pure returns (string memory) {
        return TOKEN_SYMBOL;
    }
    
    function decimals() public pure returns (uint8) {
        return DECIMALS;
    }
    
    function balanceOf(address account) public view returns (uint256) {
        return _balances[account];
    }
    
    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }
    
    function allowance(address owner, address spender) public view returns (uint256) {
        return _allowances[owner][spender];
    }
    
    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }
    
    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        uint256 currentAllowance = _allowances[from][msg.sender];
        require(currentAllowance >= amount, "ZSnailGovernance: transfer amount exceeds allowance");
        
        _transfer(from, to, amount);
        _approve(from, msg.sender, currentAllowance - amount);
        
        return true;
    }
    
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "ZSnailGovernance: transfer from zero address");
        require(to != address(0), "ZSnailGovernance: transfer to zero address");
        
        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "ZSnailGovernance: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;
        
        // Update voting power
        _updateVotingPower(from, to, amount);
        
        emit Transfer(from, to, amount);
    }
    
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "ZSnailGovernance: approve from zero address");
        require(spender != address(0), "ZSnailGovernance: approve to zero address");
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    function _updateVotingPower(address from, address to, uint256 amount) internal {
        if (from != address(0)) {
            votingPower[from] -= amount;
        }
        if (to != address(0)) {
            votingPower[to] += amount;
        }
    }
    
    // Governance Functions
    function propose(
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas,
        string memory title,
        string memory description
    ) public returns (uint256) {
        require(
            votingPower[msg.sender] >= PROPOSAL_THRESHOLD,
            "ZSnailGovernance: proposer votes below proposal threshold"
        );
        require(
            targets.length == values.length &&
            targets.length == signatures.length &&
            targets.length == calldatas.length,
            "ZSnailGovernance: proposal function information arity mismatch"
        );
        require(targets.length != 0, "ZSnailGovernance: must provide actions");
        require(targets.length <= 10, "ZSnailGovernance: too many actions");
        
        uint256 proposalId = ++proposalCount;
        uint256 startBlock = block.number + VOTING_DELAY.divCeil(15); // Assuming 15s block time
        uint256 endBlock = startBlock + VOTING_PERIOD.divCeil(15);
        
        Proposal storage newProposal = proposals[proposalId];
        newProposal.id = proposalId;
        newProposal.proposer = msg.sender;
        newProposal.title = title;
        newProposal.description = description;
        newProposal.targets = targets;
        newProposal.values = values;
        newProposal.signatures = signatures;
        newProposal.calldatas = calldatas;
        newProposal.startBlock = startBlock;
        newProposal.endBlock = endBlock;
        
        emit ProposalCreated(
            proposalId,
            msg.sender,
            targets,
            values,
            signatures,
            calldatas,
            startBlock,
            endBlock,
            description
        );
        
        return proposalId;
    }
    
    function castVote(uint256 proposalId, uint8 support) public returns (uint256) {
        return _castVote(msg.sender, proposalId, support);
    }
    
    function _castVote(address voter, uint256 proposalId, uint8 support) internal returns (uint256) {
        require(state(proposalId) == ProposalState.Active, "ZSnailGovernance: voting is closed");
        require(support <= 2, "ZSnailGovernance: invalid vote type");
        
        Proposal storage proposal = proposals[proposalId];
        Receipt storage receipt = proposal.receipts[voter];
        require(!receipt.hasVoted, "ZSnailGovernance: voter already voted");
        
        uint256 votes = votingPower[voter];
        
        if (support == 0) {
            proposal.againstVotes += votes;
        } else if (support == 1) {
            proposal.forVotes += votes;
        } else {
            proposal.abstainVotes += votes;
        }
        
        receipt.hasVoted = true;
        receipt.support = support;
        receipt.votes = votes;
        
        emit VoteCast(voter, proposalId, support, votes);
        
        return votes;
    }
    
    function state(uint256 proposalId) public view returns (ProposalState) {
        require(proposalCount >= proposalId && proposalId > 0, "ZSnailGovernance: invalid proposal id");
        
        Proposal storage proposal = proposals[proposalId];
        
        if (proposal.canceled) {
            return ProposalState.Canceled;
        } else if (block.number <= proposal.startBlock) {
            return ProposalState.Pending;
        } else if (block.number <= proposal.endBlock) {
            return ProposalState.Active;
        } else if (proposal.forVotes <= proposal.againstVotes || proposal.forVotes < quorum()) {
            return ProposalState.Defeated;
        } else if (proposal.eta == 0) {
            return ProposalState.Succeeded;
        } else if (proposal.executed) {
            return ProposalState.Executed;
        } else if (block.timestamp >= proposal.eta + EXECUTION_DELAY) {
            return ProposalState.Expired;
        } else {
            return ProposalState.Queued;
        }
    }
    
    function queue(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Succeeded, "ZSnailGovernance: proposal can only be queued if it is succeeded");
        
        Proposal storage proposal = proposals[proposalId];
        uint256 eta = block.timestamp + EXECUTION_DELAY;
        proposal.eta = bytes32(eta);
        
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _queueOrRevert(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], eta);
        }
        
        emit ProposalQueued(proposalId, eta);
    }
    
    function execute(uint256 proposalId) public {
        require(state(proposalId) == ProposalState.Queued, "ZSnailGovernance: proposal can only be executed if it is queued");
        
        Proposal storage proposal = proposals[proposalId];
        proposal.executed = true;
        
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _executeTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], uint256(proposal.eta));
        }
        
        emit ProposalExecuted(proposalId);
    }
    
    function cancel(uint256 proposalId) public {
        ProposalState currentState = state(proposalId);
        require(currentState != ProposalState.Executed, "ZSnailGovernance: cannot cancel executed proposal");
        
        Proposal storage proposal = proposals[proposalId];
        require(
            msg.sender == guardian ||
            msg.sender == proposal.proposer ||
            votingPower[proposal.proposer] < PROPOSAL_THRESHOLD,
            "ZSnailGovernance: proposer above threshold"
        );
        
        proposal.canceled = true;
        
        for (uint256 i = 0; i < proposal.targets.length; i++) {
            _cancelTransaction(proposal.targets[i], proposal.values[i], proposal.signatures[i], proposal.calldatas[i], uint256(proposal.eta));
        }
        
        emit ProposalCanceled(proposalId);
    }
    
    function _queueOrRevert(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        require(!queuedTransactions[ZSnailCrypto.generateTxHash(address(this), target, value, data, eta, 0, 0)], "ZSnailGovernance: proposal action already queued at eta");
        queuedTransactions[ZSnailCrypto.generateTxHash(address(this), target, value, data, eta, 0, 0)] = true;
    }
    
    function _executeTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        bytes32 txHash = ZSnailCrypto.generateTxHash(address(this), target, value, data, eta, 0, 0);
        require(queuedTransactions[txHash], "ZSnailGovernance: proposal action not queued");
        require(block.timestamp >= eta, "ZSnailGovernance: proposal action not ready");
        require(block.timestamp <= eta + EXECUTION_DELAY, "ZSnailGovernance: proposal action expired");
        
        queuedTransactions[txHash] = false;
        
        bytes memory callData;
        if (bytes(signature).length == 0) {
            callData = data;
        } else {
            callData = abi.encodePacked(bytes4(keccak256(bytes(signature))), data);
        }
        
        (bool success, ) = target.call{value: value}(callData);
        require(success, "ZSnailGovernance: proposal action reverted");
    }
    
    function _cancelTransaction(address target, uint256 value, string memory signature, bytes memory data, uint256 eta) internal {
        bytes32 txHash = ZSnailCrypto.generateTxHash(address(this), target, value, data, eta, 0, 0);
        queuedTransactions[txHash] = false;
    }
    
    function quorum() public view returns (uint256) {
        return totalSupply.mulDiv(QUORUM_PERCENTAGE, 100);
    }
    
    function getActions(uint256 proposalId) public view returns (
        address[] memory targets,
        uint256[] memory values,
        string[] memory signatures,
        bytes[] memory calldatas
    ) {
        Proposal storage p = proposals[proposalId];
        return (p.targets, p.values, p.signatures, p.calldatas);
    }
    
    function getReceipt(uint256 proposalId, address voter) public view returns (Receipt memory) {
        return proposals[proposalId].receipts[voter];
    }
    
    // Admin Functions
    function _setPendingAdmin(address newPendingAdmin) public onlyAdmin {
        address oldPendingAdmin = pendingAdmin;
        pendingAdmin = newPendingAdmin;
        emit NewPendingAdmin(oldPendingAdmin, newPendingAdmin);
    }
    
    function _acceptAdmin() public {
        require(msg.sender == pendingAdmin && msg.sender != address(0), "ZSnailGovernance: unauthorized");
        
        address oldAdmin = admin;
        address oldPendingAdmin = pendingAdmin;
        
        admin = pendingAdmin;
        pendingAdmin = address(0);
        
        emit NewAdmin(oldAdmin, admin);
        emit NewPendingAdmin(oldPendingAdmin, pendingAdmin);
    }
    
    function _setGuardian(address newGuardian) public onlyGovernance {
        address oldGuardian = guardian;
        guardian = newGuardian;
        emit NewGuardian(oldGuardian, newGuardian);
    }
}