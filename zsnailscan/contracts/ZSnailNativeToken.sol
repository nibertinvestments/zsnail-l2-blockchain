// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ZSnailNativeToken
 * @dev Native token implementation for ZSnail L2 blockchain
 * This is the backbone token like ETH on Ethereum - used for gas, staking, and all protocol operations
 * Not an ERC-20 token but the native blockchain currency
 */
contract ZSnailNativeToken is Ownable, ReentrancyGuard {
    
    // Token Information
    string public constant name = "ZSnail Native Token";
    string public constant symbol = "ZSNAIL";
    uint8 public constant decimals = 18;
    
    // Total supply tracking (like ETH total supply)
    uint256 public totalSupply;
    uint256 public maxSupply = 210_000_000_000 * 10**18; // 210 billion ZSNAIL max (Bitcoin-like cap)
    
    // Mining and staking parameters
    uint256 public currentBlockReward = 50 * 10**18; // 50 ZSNAIL per block initially
    uint256 public halvingInterval = 525600; // ~3 years in blocks (2 second blocks)
    uint256 public lastHalvingBlock = 0;
    
    // Distribution percentages
    uint256 public constant MINER_REWARD_PERCENTAGE = 70;
    uint256 public constant VALIDATOR_REWARD_PERCENTAGE = 20;
    uint256 public constant TREASURY_REWARD_PERCENTAGE = 10;
    
    // Protocol addresses
    address public treasuryAddress;
    address public validatorRegistry;
    address public sequencerAddress;
    
    // Staking for validators
    mapping(address => uint256) public validatorStakes;
    mapping(address => bool) public isValidator;
    mapping(address => uint256) public validatorRewards;
    
    // Mining tracking
    mapping(address => uint256) public minerRewards;
    mapping(uint256 => address) public blockMiners; // block number => miner address
    mapping(uint256 => uint256) public blockRewards; // block number => reward amount
    
    // Treasury and governance
    mapping(address => bool) public isTreasuryManager;
    uint256 public treasuryBalance;
    
    // Events for native token operations
    event BlockMined(address indexed miner, uint256 blockNumber, uint256 reward);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event ValidatorRewarded(address indexed validator, uint256 amount);
    event HalvingOccurred(uint256 blockNumber, uint256 newReward);
    event TreasuryFunded(uint256 amount);
    event GasUsed(address indexed user, uint256 amount, uint256 gasPrice);
    
    constructor(
        address _treasuryAddress,
        address _sequencerAddress,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_treasuryAddress != address(0), "Invalid treasury address");
        require(_sequencerAddress != address(0), "Invalid sequencer address");
        
        treasuryAddress = _treasuryAddress;
        sequencerAddress = _sequencerAddress;
        isTreasuryManager[_treasuryAddress] = true;
        isTreasuryManager[initialOwner] = true;
        
        // Initial supply allocation (like genesis block)
        uint256 initialSupply = 100_000_000 * 10**18; // 100 million initial supply
        totalSupply = initialSupply;
        
        // Allocate initial supply to treasury for distribution
        treasuryBalance = initialSupply;
        emit TreasuryFunded(initialSupply);
    }
    
    /**
     * @dev Mine new ZSNAIL tokens (called by sequencer/miner for each block)
     * This is equivalent to mining ETH or BTC
     */
    function mineBlock(
        address miner,
        uint256 blockNumber,
        address[] calldata activeValidators
    ) external {
        require(msg.sender == sequencerAddress, "Only sequencer can mine blocks");
        require(miner != address(0), "Invalid miner address");
        require(totalSupply + currentBlockReward <= maxSupply, "Max supply exceeded");
        
        // Check if halving should occur
        if (blockNumber >= lastHalvingBlock + halvingInterval) {
            _performHalving(blockNumber);
        }
        
        // Calculate reward distribution
        uint256 minerReward = (currentBlockReward * MINER_REWARD_PERCENTAGE) / 100;
        uint256 validatorReward = (currentBlockReward * VALIDATOR_REWARD_PERCENTAGE) / 100;
        uint256 treasuryReward = (currentBlockReward * TREASURY_REWARD_PERCENTAGE) / 100;
        
        // Mint new tokens (increase total supply)
        totalSupply += currentBlockReward;
        
        // Distribute miner reward
        minerRewards[miner] += minerReward;
        blockMiners[blockNumber] = miner;
        blockRewards[blockNumber] = minerReward;
        
        // Distribute validator rewards
        if (activeValidators.length > 0) {
            uint256 rewardPerValidator = validatorReward / activeValidators.length;
            for (uint256 i = 0; i < activeValidators.length; i++) {
                if (isValidator[activeValidators[i]]) {
                    validatorRewards[activeValidators[i]] += rewardPerValidator;
                    emit ValidatorRewarded(activeValidators[i], rewardPerValidator);
                }
            }
        }
        
        // Add to treasury
        treasuryBalance += treasuryReward;
        emit TreasuryFunded(treasuryReward);
        
        emit BlockMined(miner, blockNumber, minerReward);
    }
    
    /**
     * @dev Stake ZSNAIL to become a validator (like ETH 2.0 staking)
     */
    function stakeAsValidator(uint256 amount) external payable nonReentrant {
        require(msg.value == amount, "ETH value must match amount");
        require(amount >= 50000 * 10**18, "Minimum 50,000 ZSNAIL required"); // Min stake like ETH 2.0
        
        validatorStakes[msg.sender] += amount;
        isValidator[msg.sender] = true;
        
        emit ValidatorStaked(msg.sender, amount);
    }
    
    /**
     * @dev Unstake and withdraw ZSNAIL from validator
     */
    function unstakeValidator(uint256 amount) external nonReentrant {
        require(validatorStakes[msg.sender] >= amount, "Insufficient stake");
        require(isValidator[msg.sender], "Not a validator");
        
        validatorStakes[msg.sender] -= amount;
        
        // If stake falls below minimum, remove validator status
        if (validatorStakes[msg.sender] < 50000 * 10**18) {
            isValidator[msg.sender] = false;
        }
        
        // Transfer ZSNAIL back to validator
        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Transfer failed");
        
        emit ValidatorUnstaked(msg.sender, amount);
    }
    
    /**
     * @dev Claim mining rewards
     */
    function claimMinerRewards() external nonReentrant {
        uint256 reward = minerRewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        
        minerRewards[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Reward transfer failed");
    }
    
    /**
     * @dev Claim validator rewards
     */
    function claimValidatorRewards() external nonReentrant {
        uint256 reward = validatorRewards[msg.sender];
        require(reward > 0, "No rewards to claim");
        require(isValidator[msg.sender], "Not an active validator");
        
        validatorRewards[msg.sender] = 0;
        
        (bool success, ) = msg.sender.call{value: reward}("");
        require(success, "Reward transfer failed");
    }
    
    /**
     * @dev Burn ZSNAIL for gas (called by protocol during transactions)
     */
    function burnForGas(address user, uint256 gasAmount, uint256 gasPrice) external {
        require(msg.sender == sequencerAddress, "Only sequencer can burn gas");
        
        uint256 gasCost = gasAmount * gasPrice;
        
        // Note: In a real implementation, this would be handled at the protocol level
        // before the transaction is processed, similar to how Ethereum handles gas
        
        emit GasUsed(user, gasAmount, gasPrice);
    }
    
    /**
     * @dev Get validator stake amount
     */
    function getValidatorStake(address validator) external view returns (uint256) {
        return validatorStakes[validator];
    }
    
    /**
     * @dev Check if address is an active validator
     */
    function isActiveValidator(address validator) external view returns (bool) {
        return isValidator[validator] && validatorStakes[validator] >= 50000 * 10**18;
    }
    
    /**
     * @dev Get current block reward (changes with halvings)
     */
    function getCurrentBlockReward() external view returns (uint256) {
        return currentBlockReward;
    }
    
    /**
     * @dev Get blocks until next halving
     */
    function getBlocksUntilHalving() external view returns (uint256) {
        uint256 nextHalvingBlock = lastHalvingBlock + halvingInterval;
        if (block.number >= nextHalvingBlock) {
            return 0;
        }
        return nextHalvingBlock - block.number;
    }
    
    /**
     * @dev Perform halving (like Bitcoin halving)
     */
    function _performHalving(uint256 blockNumber) internal {
        lastHalvingBlock = blockNumber;
        currentBlockReward = currentBlockReward / 2;
        
        emit HalvingOccurred(blockNumber, currentBlockReward);
    }
    
    /**
     * @dev Treasury functions for protocol governance
     */
    function distributeTreasuryFunds(address recipient, uint256 amount) external {
        require(isTreasuryManager[msg.sender], "Not authorized");
        require(treasuryBalance >= amount, "Insufficient treasury balance");
        
        treasuryBalance -= amount;
        
        (bool success, ) = recipient.call{value: amount}("");
        require(success, "Treasury distribution failed");
    }
    
    /**
     * @dev Add treasury manager
     */
    function addTreasuryManager(address manager) external onlyOwner {
        isTreasuryManager[manager] = true;
    }
    
    /**
     * @dev Remove treasury manager
     */
    function removeTreasuryManager(address manager) external onlyOwner {
        isTreasuryManager[manager] = false;
    }
    
    /**
     * @dev Update validator registry contract
     */
    function setValidatorRegistry(address _validatorRegistry) external onlyOwner {
        validatorRegistry = _validatorRegistry;
    }
    
    /**
     * @dev Update sequencer address
     */
    function setSequencerAddress(address _sequencerAddress) external onlyOwner {
        require(_sequencerAddress != address(0), "Invalid address");
        sequencerAddress = _sequencerAddress;
    }
    
    /**
     * @dev Emergency functions
     */
    function emergencyPause() external onlyOwner {
        // Implement emergency pause functionality
        // This would pause mining, staking, etc.
    }
    
    /**
     * @dev Get total circulating supply (for tools like CoinGecko)
     */
    function getCirculatingSupply() external view returns (uint256) {
        return totalSupply - treasuryBalance;
    }
    
    /**
     * @dev Get mining statistics
     */
    function getMiningStats() external view returns (
        uint256 _totalSupply,
        uint256 _maxSupply,
        uint256 _currentReward,
        uint256 _halvingInterval,
        uint256 _blocksUntilHalving
    ) {
        uint256 nextHalvingBlock = lastHalvingBlock + halvingInterval;
        uint256 blocksUntilHalving = block.number >= nextHalvingBlock ? 0 : nextHalvingBlock - block.number;
        
        return (
            totalSupply,
            maxSupply,
            currentBlockReward,
            halvingInterval,
            blocksUntilHalving
        );
    }
    
    /**
     * @dev Receive function to accept ZSNAIL payments
     */
    receive() external payable {
        // Accept ZSNAIL payments (like ETH)
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        // Handle any calls to this contract
    }
}