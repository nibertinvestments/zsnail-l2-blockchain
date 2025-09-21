// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./ZSnailToken.sol";

/**
 * @title Validator Node Manager
 * @dev Manages validator nodes, consensus, and validation rewards
 */
contract ValidatorNode is Ownable, ReentrancyGuard {
    
    ZSnailToken public zsnailToken;
    
    struct Validator {
        address nodeAddress;
        string nodeUrl;
        uint256 stake;
        uint256 reputation;
        uint256 blocksValidated;
        uint256 lastActiveBlock;
        bool isActive;
        string region;
        uint256 joinedAt;
    }
    
    struct ValidationResult {
        address validator;
        uint256 blockNumber;
        bytes32 blockHash;
        bool isValid;
        uint256 timestamp;
    }
    
    // Validator management
    mapping(address => Validator) public validators;
    address[] public validatorList;
    mapping(uint256 => ValidationResult[]) public blockValidations;
    
    // Configuration
    uint256 public minStakeAmount = 30000 * 10**18; // 30K ZSNAIL
    uint256 public maxValidators = 100;
    uint256 public consensusThreshold = 67; // 67% agreement needed
    uint256 public validationReward = 50 * 10**18; // 50 ZSNAIL per validation
    uint256 public slashingAmount = 1000 * 10**18; // 1K ZSNAIL penalty
    
    // Performance tracking
    mapping(address => uint256) public validatorScores;
    mapping(address => uint256) public lastRewardBlock;
    
    // Events
    event ValidatorRegistered(address indexed validator, uint256 stake, string nodeUrl);
    event ValidatorRemoved(address indexed validator, string reason);
    event BlockValidated(uint256 indexed blockNumber, address indexed validator, bool isValid);
    event ConsensusReached(uint256 indexed blockNumber, bytes32 blockHash, bool isValid);
    event ValidatorSlashed(address indexed validator, uint256 amount, string reason);
    event ValidationRewardPaid(address indexed validator, uint256 amount);
    event ValidatorStatusChanged(address indexed validator, bool isActive);
    
    constructor(address _zsnailToken, address initialOwner) Ownable(initialOwner) {
        zsnailToken = ZSnailToken(_zsnailToken);
    }
    
    /**
     * @dev Register as a validator node
     * @param nodeUrl URL/IP of the validator node
     * @param region Geographic region of the node
     */
    function registerValidator(string memory nodeUrl, string memory region) external nonReentrant {
        require(bytes(nodeUrl).length > 0, "Node URL required");
        require(!validators[msg.sender].isActive, "Already registered");
        require(validatorList.length < maxValidators, "Max validators reached");
        
        // Check stake requirement
        uint256 stake = zsnailToken.getValidatorStake(msg.sender);
        require(stake >= minStakeAmount, "Insufficient stake");
        
        // Register validator
        validators[msg.sender] = Validator({
            nodeAddress: msg.sender,
            nodeUrl: nodeUrl,
            stake: stake,
            reputation: 100, // Start with base reputation
            blocksValidated: 0,
            lastActiveBlock: block.number,
            isActive: true,
            region: region,
            joinedAt: block.timestamp
        });
        
        validatorList.push(msg.sender);
        validatorScores[msg.sender] = 100;
        
        emit ValidatorRegistered(msg.sender, stake, nodeUrl);
    }
    
    /**
     * @dev Submit a block validation result
     * @param blockNumber Block number being validated
     * @param blockHash Hash of the block
     * @param isValid Whether the block is valid
     */
    function submitValidation(uint256 blockNumber, bytes32 blockHash, bool isValid) external {
        require(validators[msg.sender].isActive, "Not an active validator");
        require(blockNumber <= block.number, "Cannot validate future blocks");
        
        // Check if already validated this block
        ValidationResult[] storage validations = blockValidations[blockNumber];
        for (uint i = 0; i < validations.length; i++) {
            require(validations[i].validator != msg.sender, "Already validated this block");
        }
        
        // Submit validation
        validations.push(ValidationResult({
            validator: msg.sender,
            blockNumber: blockNumber,
            blockHash: blockHash,
            isValid: isValid,
            timestamp: block.timestamp
        }));
        
        // Update validator stats
        validators[msg.sender].blocksValidated++;
        validators[msg.sender].lastActiveBlock = block.number;
        
        emit BlockValidated(blockNumber, msg.sender, isValid);
        
        // Check if consensus reached
        _checkConsensus(blockNumber);
        
        // Reward validator
        _rewardValidator(msg.sender);
    }
    
    /**
     * @dev Check if consensus has been reached for a block
     */
    function _checkConsensus(uint256 blockNumber) internal {
        ValidationResult[] storage validations = blockValidations[blockNumber];
        uint256 totalValidations = validations.length;
        
        if (totalValidations >= _getMinValidatorsForConsensus()) {
            uint256 validCount = 0;
            bytes32 consensusHash;
            
            // Count valid vs invalid
            for (uint i = 0; i < totalValidations; i++) {
                if (validations[i].isValid) {
                    validCount++;
                    if (consensusHash == bytes32(0)) {
                        consensusHash = validations[i].blockHash;
                    }
                }
            }
            
            // Check if consensus threshold met
            bool consensus = (validCount * 100 / totalValidations) >= consensusThreshold;
            
            emit ConsensusReached(blockNumber, consensusHash, consensus);
            
            // Slash validators who disagreed with consensus
            _handleDisagreement(blockNumber, consensus);
        }
    }
    
    /**
     * @dev Handle validators who disagreed with consensus
     */
    function _handleDisagreement(uint256 blockNumber, bool consensusValid) internal {
        ValidationResult[] storage validations = blockValidations[blockNumber];
        
        for (uint i = 0; i < validations.length; i++) {
            ValidationResult storage validation = validations[i];
            
            // If validator disagreed with consensus
            if (validation.isValid != consensusValid) {
                _slashValidator(validation.validator, "Consensus disagreement");
            } else {
                // Reward validators who agreed with consensus
                _bonusReward(validation.validator);
            }
        }
    }
    
    /**
     * @dev Slash a validator for malicious behavior
     */
    function _slashValidator(address validator, string memory reason) internal {
        require(validators[validator].isActive, "Validator not active");
        
        // Reduce reputation
        if (validatorScores[validator] > 10) {
            validatorScores[validator] -= 10;
        }
        
        // Remove from active list if score too low
        if (validatorScores[validator] < 50) {
            validators[validator].isActive = false;
            emit ValidatorStatusChanged(validator, false);
        }
        
        emit ValidatorSlashed(validator, slashingAmount, reason);
    }
    
    /**
     * @dev Reward validator for correct validation
     */
    function _rewardValidator(address validator) internal {
        // Prevent reward spam
        if (lastRewardBlock[validator] >= block.number) return;
        
        lastRewardBlock[validator] = block.number;
        
        // Increase reputation score
        if (validatorScores[validator] < 100) {
            validatorScores[validator] += 1;
        }
        
        // Distribute ZSNAIL reward through token contract
        // Note: This would need to be called by the token contract owner
        emit ValidationRewardPaid(validator, validationReward);
    }
    
    /**
     * @dev Give bonus reward for consensus agreement
     */
    function _bonusReward(address validator) internal {
        validatorScores[validator] += 2;
        if (validatorScores[validator] > 100) {
            validatorScores[validator] = 100;
        }
    }
    
    /**
     * @dev Get minimum validators needed for consensus
     */
    function _getMinValidatorsForConsensus() internal view returns (uint256) {
        uint256 activeValidators = getActiveValidatorCount();
        return (activeValidators * consensusThreshold) / 100;
    }
    
    /**
     * @dev Remove inactive validators
     */
    function removeInactiveValidators() external {
        for (uint i = 0; i < validatorList.length; i++) {
            address validator = validatorList[i];
            
            // Remove if inactive for 100 blocks
            if (validators[validator].isActive && 
                block.number - validators[validator].lastActiveBlock > 100) {
                
                validators[validator].isActive = false;
                emit ValidatorRemoved(validator, "Inactivity");
            }
        }
    }
    
    /**
     * @dev Get active validator count
     */
    function getActiveValidatorCount() public view returns (uint256 count) {
        for (uint i = 0; i < validatorList.length; i++) {
            if (validators[validatorList[i]].isActive) {
                count++;
            }
        }
    }
    
    /**
     * @dev Get validator information
     */
    function getValidator(address validatorAddress) external view returns (
        string memory nodeUrl,
        uint256 stake,
        uint256 reputation,
        uint256 blocksValidated,
        bool isActive,
        string memory region
    ) {
        Validator storage v = validators[validatorAddress];
        return (v.nodeUrl, v.stake, v.reputation, v.blocksValidated, v.isActive, v.region);
    }
    
    /**
     * @dev Get block validation results
     */
    function getBlockValidations(uint256 blockNumber) external view returns (
        address[] memory validatorAddresses,
        bool[] memory results,
        uint256[] memory timestamps
    ) {
        ValidationResult[] storage validations = blockValidations[blockNumber];
        uint256 length = validations.length;
        
        validatorAddresses = new address[](length);
        results = new bool[](length);
        timestamps = new uint256[](length);
        
        for (uint i = 0; i < length; i++) {
            validatorAddresses[i] = validations[i].validator;
            results[i] = validations[i].isValid;
            timestamps[i] = validations[i].timestamp;
        }
    }
    
    // Owner functions
    function updateConsensusThreshold(uint256 newThreshold) external onlyOwner {
        require(newThreshold > 50 && newThreshold <= 100, "Invalid threshold");
        consensusThreshold = newThreshold;
    }
    
    function updateValidationReward(uint256 newReward) external onlyOwner {
        validationReward = newReward;
    }
    
    function updateMinStake(uint256 newMin) external onlyOwner {
        minStakeAmount = newMin;
    }
    
    function emergencyRemoveValidator(address validator, string memory reason) external onlyOwner {
        validators[validator].isActive = false;
        emit ValidatorRemoved(validator, reason);
    }
}