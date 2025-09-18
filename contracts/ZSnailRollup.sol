// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/MessageHashUtils.sol";

/**
 * @title ZSnailRollup
 * @dev Main rollup contract for ZSnail L2 blockchain
 * @author ZSnail Blockchain Team
 * 
 * This contract implements an optimistic rollup system with the following features:
 * - State root commitments from sequencers
 * - Fraud proof challenge mechanism
 * - Validator management and staking
 * - L1 ↔ L2 message passing
 * - Emergency pause functionality
 */
contract ZSnailRollup is ReentrancyGuard, AccessControl, Pausable {
    using ECDSA for bytes32;
    using MessageHashUtils for bytes32;

    // =============================================================
    //                           CONSTANTS
    // =============================================================

    /// @dev Role for sequencers who can submit state updates
    bytes32 public constant SEQUENCER_ROLE = keccak256("SEQUENCER_ROLE");
    
    /// @dev Role for validators who can challenge state updates
    bytes32 public constant VALIDATOR_ROLE = keccak256("VALIDATOR_ROLE");
    
    /// @dev Role for pausing the contract in emergencies
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");

    /// @dev Challenge period duration (7 days)
    uint256 public constant CHALLENGE_PERIOD = 7 days;
    
    /// @dev Minimum stake required for validators
    uint256 public constant MIN_VALIDATOR_STAKE = 1 ether;
    
    /// @dev Maximum number of state roots to keep
    uint256 public constant MAX_STATE_ROOTS = 1000;

    // =============================================================
    //                            STRUCTS
    // =============================================================

    /**
     * @dev Represents a state update batch
     */
    struct StateBatch {
        bytes32 stateRoot;          // Merkle root of L2 state
        bytes32 transactionRoot;    // Merkle root of transactions
        uint256 blockNumber;        // L2 block number
        uint256 timestamp;          // Submission timestamp
        uint256 challengeDeadline;  // When challenge period expires
        address sequencer;          // Sequencer who submitted
        bool finalized;            // Whether the batch is finalized
        uint256 challengeCount;    // Number of active challenges
    }

    /**
     * @dev Represents a fraud proof challenge
     */
    struct Challenge {
        address challenger;         // Who initiated the challenge
        uint256 batchIndex;        // Which batch is being challenged
        bytes32 claimedStateRoot;  // Challenger's claimed correct state root
        uint256 stake;             // Challenger's stake
        uint256 deadline;          // Challenge resolution deadline
        bool resolved;             // Whether challenge is resolved
        bool successful;           // Whether challenge was successful
    }

    /**
     * @dev Validator information
     */
    struct Validator {
        uint256 stake;             // Amount staked
        uint256 lastActivity;      // Last activity timestamp
        bool active;               // Whether validator is active
        uint256 successfulChallenges; // Number of successful challenges
        uint256 failedChallenges;  // Number of failed challenges
    }

    // =============================================================
    //                        STATE VARIABLES
    // =============================================================

    /// @dev Array of all state batches
    StateBatch[] public stateBatches;
    
    /// @dev Mapping from challenge ID to challenge details
    mapping(uint256 => Challenge) public challenges;
    
    /// @dev Mapping from validator address to validator info
    mapping(address => Validator) public validators;
    
    /// @dev Current challenge counter
    uint256 public challengeCounter;
    
    /// @dev Total value locked in the rollup
    uint256 public totalValueLocked;
    
    /// @dev L2 chain ID
    uint256 public immutable L2_CHAIN_ID;

    // =============================================================
    //                            EVENTS
    // =============================================================

    /**
     * @dev Emitted when a new state batch is submitted
     */
    event StateBatchSubmitted(
        uint256 indexed batchIndex,
        bytes32 indexed stateRoot,
        bytes32 indexed transactionRoot,
        uint256 blockNumber,
        address sequencer
    );

    /**
     * @dev Emitted when a state batch is finalized
     */
    event StateBatchFinalized(
        uint256 indexed batchIndex,
        bytes32 indexed stateRoot
    );

    /**
     * @dev Emitted when a challenge is initiated
     */
    event ChallengeInitiated(
        uint256 indexed challengeId,
        uint256 indexed batchIndex,
        address indexed challenger,
        bytes32 claimedStateRoot
    );

    /**
     * @dev Emitted when a challenge is resolved
     */
    event ChallengeResolved(
        uint256 indexed challengeId,
        bool indexed successful,
        address indexed challenger
    );

    /**
     * @dev Emitted when a validator is registered
     */
    event ValidatorRegistered(
        address indexed validator,
        uint256 stake
    );

    /**
     * @dev Emitted when a validator is slashed
     */
    event ValidatorSlashed(
        address indexed validator,
        uint256 amount,
        string reason
    );

    // =============================================================
    //                           MODIFIERS
    // =============================================================

    /**
     * @dev Ensures the caller is an active validator
     */
    modifier onlyActiveValidator() {
        require(validators[msg.sender].active, "Not an active validator");
        require(validators[msg.sender].stake >= MIN_VALIDATOR_STAKE, "Insufficient stake");
        _;
    }

    /**
     * @dev Ensures the batch index is valid
     */
    modifier validBatchIndex(uint256 batchIndex) {
        require(batchIndex < stateBatches.length, "Invalid batch index");
        _;
    }

    /**
     * @dev Ensures the challenge ID is valid
     */
    modifier validChallengeId(uint256 challengeId) {
        require(challengeId < challengeCounter, "Invalid challenge ID");
        _;
    }

    // =============================================================
    //                          CONSTRUCTOR
    // =============================================================

    /**
     * @dev Contract constructor
     * @param _l2ChainId The L2 chain ID
     * @param _admin The admin address
     */
    constructor(uint256 _l2ChainId, address _admin) {
        L2_CHAIN_ID = _l2ChainId;
        
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        _grantRole(PAUSER_ROLE, _admin);
        
        // Initialize genesis state
        stateBatches.push(StateBatch({
            stateRoot: bytes32(0),
            transactionRoot: bytes32(0),
            blockNumber: 0,
            timestamp: block.timestamp,
            challengeDeadline: block.timestamp,
            sequencer: address(0),
            finalized: true,
            challengeCount: 0
        }));
    }

    // =============================================================
    //                      SEQUENCER FUNCTIONS
    // =============================================================

    /**
     * @dev Submit a new state batch
     * @param _stateRoot The new state root
     * @param _transactionRoot The transaction root for this batch
     * @param _blockNumber The L2 block number
     */
    function submitStateBatch(
        bytes32 _stateRoot,
        bytes32 _transactionRoot,
        uint256 _blockNumber
    ) external onlyRole(SEQUENCER_ROLE) whenNotPaused nonReentrant {
        require(_stateRoot != bytes32(0), "Invalid state root");
        require(_blockNumber > getLatestBlockNumber(), "Block number must increase");
        
        uint256 batchIndex = stateBatches.length;
        uint256 challengeDeadline = block.timestamp + CHALLENGE_PERIOD;
        
        stateBatches.push(StateBatch({
            stateRoot: _stateRoot,
            transactionRoot: _transactionRoot,
            blockNumber: _blockNumber,
            timestamp: block.timestamp,
            challengeDeadline: challengeDeadline,
            sequencer: msg.sender,
            finalized: false,
            challengeCount: 0
        }));

        emit StateBatchSubmitted(
            batchIndex,
            _stateRoot,
            _transactionRoot,
            _blockNumber,
            msg.sender
        );

        // Auto-finalize older batches that are past challenge period
        _finalizeOldBatches();
    }

    // =============================================================
    //                      VALIDATOR FUNCTIONS
    // =============================================================

    /**
     * @dev Register as a validator by staking ETH
     */
    function registerValidator() external payable whenNotPaused {
        require(msg.value >= MIN_VALIDATOR_STAKE, "Insufficient stake");
        require(!validators[msg.sender].active, "Already registered");

        validators[msg.sender] = Validator({
            stake: msg.value,
            lastActivity: block.timestamp,
            active: true,
            successfulChallenges: 0,
            failedChallenges: 0
        });

        _grantRole(VALIDATOR_ROLE, msg.sender);
        emit ValidatorRegistered(msg.sender, msg.value);
    }

    /**
     * @dev Add more stake to existing validator
     */
    function addStake() external payable onlyRole(VALIDATOR_ROLE) whenNotPaused {
        require(msg.value > 0, "Must stake more than 0");
        validators[msg.sender].stake += msg.value;
    }

    /**
     * @dev Initiate a fraud proof challenge
     * @param _batchIndex The batch to challenge
     * @param _claimedStateRoot The correct state root according to challenger
     */
    function initiateChallenge(
        uint256 _batchIndex,
        bytes32 _claimedStateRoot
    ) external onlyActiveValidator validBatchIndex(_batchIndex) whenNotPaused nonReentrant {
        StateBatch storage batch = stateBatches[_batchIndex];
        require(!batch.finalized, "Batch already finalized");
        require(block.timestamp < batch.challengeDeadline, "Challenge period expired");
        require(_claimedStateRoot != batch.stateRoot, "Same state root");

        uint256 challengeId = challengeCounter++;
        uint256 challengeStake = MIN_VALIDATOR_STAKE / 2; // 50% of minimum stake required
        
        require(validators[msg.sender].stake >= challengeStake, "Insufficient stake for challenge");

        challenges[challengeId] = Challenge({
            challenger: msg.sender,
            batchIndex: _batchIndex,
            claimedStateRoot: _claimedStateRoot,
            stake: challengeStake,
            deadline: block.timestamp + 1 days, // 1 day to resolve
            resolved: false,
            successful: false
        });

        batch.challengeCount++;
        validators[msg.sender].stake -= challengeStake;
        validators[msg.sender].lastActivity = block.timestamp;

        emit ChallengeInitiated(challengeId, _batchIndex, msg.sender, _claimedStateRoot);
    }

    /**
     * @dev Resolve a fraud proof challenge
     * @param _challengeId The challenge to resolve
     * @param _proof The fraud proof data
     */
    function resolveChallenge(
        uint256 _challengeId,
        bytes calldata _proof
    ) external validChallengeId(_challengeId) whenNotPaused nonReentrant {
        Challenge storage challenge = challenges[_challengeId];
        require(!challenge.resolved, "Challenge already resolved");
        require(block.timestamp < challenge.deadline, "Challenge deadline passed");

        // In a real implementation, this would verify the fraud proof
        // For this example, we'll use a simplified verification
        bool isValidProof = _verifyFraudProof(_challengeId, _proof);
        
        challenge.resolved = true;
        challenge.successful = isValidProof;

        StateBatch storage batch = stateBatches[challenge.batchIndex];
        batch.challengeCount--;

        if (isValidProof) {
            // Challenge successful - update state root and slash sequencer
            batch.stateRoot = challenge.claimedStateRoot;
            validators[challenge.challenger].stake += challenge.stake * 2; // Reward challenger
            validators[challenge.challenger].successfulChallenges++;
            
            // Slash the sequencer (if they are also a validator)
            if (validators[batch.sequencer].active) {
                _slashValidator(batch.sequencer, "Invalid state submission");
            }
        } else {
            // Challenge failed - slash challenger
            validators[challenge.challenger].failedChallenges++;
            _slashValidator(challenge.challenger, "False challenge");
        }

        emit ChallengeResolved(_challengeId, isValidProof, challenge.challenger);
    }

    // =============================================================
    //                      ADMIN FUNCTIONS
    // =============================================================

    /**
     * @dev Add a new sequencer
     * @param _sequencer The address to grant sequencer role
     */
    function addSequencer(address _sequencer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(SEQUENCER_ROLE, _sequencer);
    }

    /**
     * @dev Remove a sequencer
     * @param _sequencer The address to revoke sequencer role from
     */
    function removeSequencer(address _sequencer) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(SEQUENCER_ROLE, _sequencer);
    }

    /**
     * @dev Emergency pause
     */
    function pause() external onlyRole(PAUSER_ROLE) {
        _pause();
    }

    /**
     * @dev Unpause
     */
    function unpause() external onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // =============================================================
    //                       VIEW FUNCTIONS
    // =============================================================

    /**
     * @dev Get the latest finalized state root
     */
    function getLatestFinalizedStateRoot() external view returns (bytes32) {
        for (uint256 i = stateBatches.length - 1; i >= 0; i--) {
            if (stateBatches[i].finalized) {
                return stateBatches[i].stateRoot;
            }
        }
        return bytes32(0);
    }

    /**
     * @dev Get the latest block number
     */
    function getLatestBlockNumber() public view returns (uint256) {
        if (stateBatches.length == 0) return 0;
        return stateBatches[stateBatches.length - 1].blockNumber;
    }

    /**
     * @dev Get the number of state batches
     */
    function getStateBatchCount() external view returns (uint256) {
        return stateBatches.length;
    }

    /**
     * @dev Get state batch by index
     */
    function getStateBatch(uint256 _index) external view validBatchIndex(_index) returns (StateBatch memory) {
        return stateBatches[_index];
    }

    /**
     * @dev Check if a validator is active
     */
    function isActiveValidator(address _validator) external view returns (bool) {
        return validators[_validator].active && validators[_validator].stake >= MIN_VALIDATOR_STAKE;
    }

    /**
     * @dev Get validator information
     */
    function getValidator(address _validator) external view returns (Validator memory) {
        return validators[_validator];
    }

    // =============================================================
    //                     INTERNAL FUNCTIONS
    // =============================================================

    /**
     * @dev Finalize old batches that are past challenge period
     */
    function _finalizeOldBatches() internal {
        uint256 currentTime = block.timestamp;
        
        for (uint256 i = 0; i < stateBatches.length; i++) {
            StateBatch storage batch = stateBatches[i];
            
            if (!batch.finalized && 
                currentTime >= batch.challengeDeadline && 
                batch.challengeCount == 0) {
                
                batch.finalized = true;
                emit StateBatchFinalized(i, batch.stateRoot);
            }
        }
    }

    /**
     * @dev Verify fraud proof (simplified implementation)
     * @param _challengeId The challenge ID
     * @param _proof The proof data
     */
    function _verifyFraudProof(uint256 _challengeId, bytes calldata _proof) internal pure returns (bool) {
        // In a real implementation, this would:
        // 1. Parse the proof data
        // 2. Re-execute the disputed transaction
        // 3. Compare the resulting state with the claimed state
        // 4. Return true if the challenger is correct
        
        // For this example, we'll use a simple check
        return _proof.length > 0 && uint256(keccak256(_proof)) % 2 == 0;
    }

    /**
     * @dev Slash a validator
     * @param _validator The validator to slash
     * @param _reason The reason for slashing
     */
    function _slashValidator(address _validator, string memory _reason) internal {
        Validator storage validator = validators[_validator];
        uint256 slashAmount = validator.stake / 10; // Slash 10% of stake
        
        validator.stake -= slashAmount;
        
        if (validator.stake < MIN_VALIDATOR_STAKE) {
            validator.active = false;
            _revokeRole(VALIDATOR_ROLE, _validator);
        }

        emit ValidatorSlashed(_validator, slashAmount, _reason);
    }

    /**
     * @dev Withdraw validator stake (only when inactive)
     */
    function withdrawStake() external nonReentrant {
        Validator storage validator = validators[msg.sender];
        require(!validator.active, "Validator still active");
        require(validator.stake > 0, "No stake to withdraw");

        uint256 amount = validator.stake;
        validator.stake = 0;

        (bool success, ) = payable(msg.sender).call{value: amount}("");
        require(success, "Withdrawal failed");
    }
}