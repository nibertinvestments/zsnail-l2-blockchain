// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title ValidatorRegistry
 * @dev Registry for ZSnail L2 validators with staking and slashing
 */
contract ValidatorRegistry is Ownable, ReentrancyGuard {
    
    struct Validator {
        address validatorAddress;
        string nodeUrl;
        uint256 stake;
        uint256 reputation;
        uint256 blocksValidated;
        uint256 lastActiveBlock;
        bool isActive;
        string region;
        uint256 joinedAt;
        uint256 slashedAmount;
    }
    
    struct ValidationSubmission {
        bytes32 blockHash;
        uint256 blockNumber;
        bytes32 stateRoot;
        uint256 timestamp;
        bool isValid;
    }
    
    // State variables
    address public zsnailNativeToken; // Address of the native ZSNAIL token contract
    mapping(address => Validator) public validators;
    mapping(uint256 => mapping(address => ValidationSubmission)) public validations;
    address[] public validatorList;
    
    // Configuration
    uint256 public minStake;
    uint256 public maxValidators;
    uint256 public consensusThreshold; // Percentage (e.g., 67 for 67%)
    uint256 public slashingPercentage; // Percentage to slash for misbehavior
    uint256 public validationReward;
    uint256 public blockTimeout; // Blocks before validator is considered inactive
    
    // Events
    event ValidatorRegistered(address indexed validator, uint256 stake, string nodeUrl);
    event ValidatorActivated(address indexed validator);
    event ValidatorDeactivated(address indexed validator, string reason);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event ValidationSubmitted(address indexed validator, uint256 blockNumber, bytes32 blockHash);
    event RewardDistributed(address indexed validator, uint256 amount);
    event StakeIncreased(address indexed validator, uint256 newStake);
    event StakeWithdrawn(address indexed validator, uint256 amount);
    
    constructor(
        address _zsnailNativeToken,
        uint256 _minStake,
        uint256 _consensusThreshold,
        address initialOwner
    ) Ownable(initialOwner) {
        require(_zsnailNativeToken != address(0), "Invalid token address");
        require(_minStake > 0, "Minimum stake must be positive");
        require(_consensusThreshold > 50 && _consensusThreshold <= 100, "Invalid consensus threshold");
        
        zsnailNativeToken = _zsnailNativeToken;
        minStake = _minStake;
        consensusThreshold = _consensusThreshold;
        maxValidators = 100;
        slashingPercentage = 10; // 10% slash for misbehavior
        validationReward = 1 ether; // 1 ZSNAIL per validation
        blockTimeout = 100; // 100 blocks (~200 seconds)
    }
    
    /**
     * @dev Register as a validator using native ZSNAIL staking
     */
    function registerValidator(
        string memory nodeUrl,
        string memory region
    ) external payable nonReentrant {
        require(bytes(nodeUrl).length > 0, "Node URL required");
        require(bytes(region).length > 0, "Region required");
        require(msg.value >= minStake, "Insufficient stake");
        require(!validators[msg.sender].isActive, "Already registered");
        require(validatorList.length < maxValidators, "Max validators reached");
        
        // Register validator with native ZSNAIL stake
        validators[msg.sender] = Validator({
            validatorAddress: msg.sender,
            nodeUrl: nodeUrl,
            stake: msg.value,
            reputation: 100, // Start with 100% reputation
            blocksValidated: 0,
            lastActiveBlock: block.number,
            isActive: true,
            region: region,
            joinedAt: block.timestamp,
            slashedAmount: 0
        });
        
        validatorList.push(msg.sender);
        
        emit ValidatorRegistered(msg.sender, msg.value, nodeUrl);
        emit ValidatorActivated(msg.sender);
    }
    
    /**
     * @dev Submit block validation
     */
    function submitValidation(
        uint256 blockNumber,
        bytes32 blockHash,
        bytes32 stateRoot
    ) external {
        require(validators[msg.sender].isActive, "Not an active validator");
        require(blockNumber > 0, "Invalid block number");
        require(blockHash != bytes32(0), "Invalid block hash");
        require(stateRoot != bytes32(0), "Invalid state root");
        
        // Update validator activity
        validators[msg.sender].lastActiveBlock = block.number;
        validators[msg.sender].blocksValidated++;
        
        // Store validation
        validations[blockNumber][msg.sender] = ValidationSubmission({
            blockHash: blockHash,
            blockNumber: blockNumber,
            stateRoot: stateRoot,
            timestamp: block.timestamp,
            isValid: true
        });
        
        emit ValidationSubmitted(msg.sender, blockNumber, blockHash);
        
        // Distribute reward
        _distributeReward(msg.sender);
    }
    
    /**
     * @dev Check if block reached consensus
     */
    function hasConsensus(uint256 blockNumber, bytes32 blockHash) external view returns (bool) {
        uint256 validValidations = 0;
        uint256 totalActiveValidators = getActiveValidatorCount();
        
        for (uint256 i = 0; i < validatorList.length; i++) {
            address validator = validatorList[i];
            if (validators[validator].isActive) {
                ValidationSubmission memory validation = validations[blockNumber][validator];
                if (validation.blockHash == blockHash && validation.isValid) {
                    validValidations++;
                }
            }
        }
        
        return (validValidations * 100 / totalActiveValidators) >= consensusThreshold;
    }
    
    /**
     * @dev Slash validator for misbehavior
     */
    function slashValidator(address validator, string memory reason) external onlyOwner {
        require(validators[validator].isActive, "Validator not active");
        
        uint256 slashAmount = validators[validator].stake * slashingPercentage / 100;
        validators[validator].stake -= slashAmount;
        validators[validator].slashedAmount += slashAmount;
        validators[validator].reputation = validators[validator].reputation > 20 ? 
            validators[validator].reputation - 20 : 0;
        
        // Deactivate if stake below minimum
        if (validators[validator].stake < minStake) {
            validators[validator].isActive = false;
            emit ValidatorDeactivated(validator, "Stake below minimum after slashing");
        }
        
        emit ValidatorSlashed(validator, slashAmount, reason);
    }
    
    /**
     * @dev Increase stake with native ZSNAIL
     */
    function increaseStake() external payable nonReentrant {
        require(validators[msg.sender].isActive, "Not an active validator");
        require(msg.value > 0, "Amount must be positive");
        
        validators[msg.sender].stake += msg.value;
        emit StakeIncreased(msg.sender, validators[msg.sender].stake);
    }
    
    /**
     * @dev Withdraw stake (deactivate validator)
     */
    function withdrawStake() external nonReentrant {
        require(validators[msg.sender].isActive, "Not an active validator");
        
        uint256 stakeAmount = validators[msg.sender].stake;
        validators[msg.sender].isActive = false;
        validators[msg.sender].stake = 0;
        
        // Remove from active list (gas optimization could be improved)
        for (uint256 i = 0; i < validatorList.length; i++) {
            if (validatorList[i] == msg.sender) {
                validatorList[i] = validatorList[validatorList.length - 1];
                validatorList.pop();
                break;
            }
        }
        
        // Return ZSNAIL stake
        (bool success, ) = msg.sender.call{value: stakeAmount}("");
        require(success, "Stake withdrawal failed");
        
        emit StakeWithdrawn(msg.sender, stakeAmount);
        emit ValidatorDeactivated(msg.sender, "Voluntary withdrawal");
    }
    
    /**
     * @dev Get active validator count
     */
    function getActiveValidatorCount() public view returns (uint256 count) {
        for (uint256 i = 0; i < validatorList.length; i++) {
            if (validators[validatorList[i]].isActive) {
                count++;
            }
        }
    }
    
    /**
     * @dev Get all active validators
     */
    function getActiveValidators() external view returns (address[] memory) {
        uint256 activeCount = getActiveValidatorCount();
        address[] memory activeValidators = new address[](activeCount);
        uint256 index = 0;
        
        for (uint256 i = 0; i < validatorList.length; i++) {
            if (validators[validatorList[i]].isActive) {
                activeValidators[index] = validatorList[i];
                index++;
            }
        }
        
        return activeValidators;
    }
    
    /**
     * @dev Get validator info
     */
    function getValidator(address validator) external view returns (
        string memory nodeUrl,
        uint256 stake,
        uint256 reputation,
        uint256 blocksValidated,
        bool isActive,
        string memory region
    ) {
        Validator memory v = validators[validator];
        return (v.nodeUrl, v.stake, v.reputation, v.blocksValidated, v.isActive, v.region);
    }
    
    /**
     * @dev Clean up inactive validators
     */
    function cleanupInactiveValidators() external {
        for (uint256 i = 0; i < validatorList.length; i++) {
            address validator = validatorList[i];
            
            if (validators[validator].isActive && 
                block.number - validators[validator].lastActiveBlock > blockTimeout) {
                
                validators[validator].isActive = false;
                emit ValidatorDeactivated(validator, "Inactivity timeout");
            }
        }
    }
    
    /**
     * @dev Distribute validation reward
     */
    function _distributeReward(address validator) internal {
        if (validationReward > 0) {
            // Mint or transfer reward (simplified for now)
            emit RewardDistributed(validator, validationReward);
        }
    }
    
    // Admin functions
    function updateMinStake(uint256 _minStake) external onlyOwner {
        minStake = _minStake;
    }
    
    function updateConsensusThreshold(uint256 _threshold) external onlyOwner {
        require(_threshold > 50 && _threshold <= 100, "Invalid threshold");
        consensusThreshold = _threshold;
    }
    
    function updateValidationReward(uint256 _reward) external onlyOwner {
        validationReward = _reward;
    }
    
    function updateSlashingPercentage(uint256 _percentage) external onlyOwner {
        require(_percentage <= 50, "Slashing too high");
        slashingPercentage = _percentage;
    }
    
    function emergencyPause() external onlyOwner {
        // Emergency pause functionality
        // Implementation depends on requirements
    }
}