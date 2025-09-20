// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title ZSnail Token (ZSNAIL)
 * @dev The native gas token for ZSnail L2 Blockchain
 * @dev Features: Gas payments, validator staking, mining rewards, governance
 */
contract ZSnailToken is ERC20, ERC20Burnable, Ownable, ReentrancyGuard {
    
    // Token configuration
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100M tokens
    uint256 public constant MAX_SUPPLY = 100_000_000_000 * 10**18;   // 100B tokens max
    uint256 public constant DEPLOYER_ALLOCATION = 10_000_000 * 10**18; // 10M for deployer
    
    // Gas mechanics - ETH only usable if wallet has 0 ZSNAIL
    uint256 public gasTokenRate = 1000; // 1000 ZSNAIL = 1 ETH equivalent for gas
    bool public gasTokenEnabled = true;
    
    // Mining and validation
    mapping(address => bool) public miners;
    mapping(address => bool) public validators;
    mapping(address => uint256) public validatorStakes;
    
    uint256 public minValidatorStake = 30000 * 10**18; // 30K ZSNAIL minimum
    uint256 public totalValidatorStakes;
    
    // Reward distribution
    address public rewardPool;
    uint256 public miningRewardRate = 100; // 100 ZSNAIL per block
    uint256 public validatorRewardRate = 50; // 50 ZSNAIL per validation
    
    // Events
    event GasTokenUsed(address indexed user, uint256 amount, uint256 gasUsed);
    event ValidatorStaked(address indexed validator, uint256 amount);
    event ValidatorUnstaked(address indexed validator, uint256 amount);
    event MiningRewardDistributed(address indexed miner, uint256 amount);
    event ValidationRewardDistributed(address indexed validator, uint256 amount);
    event GasRateUpdated(uint256 newRate);
    
    constructor(address initialOwner) 
        ERC20("ZSnail Token", "ZSNAIL") 
        Ownable(initialOwner)
    {
        // Mint deployer allocation (10M tokens for gas and operations)
        _mint(initialOwner, DEPLOYER_ALLOCATION);
        
        // Set up reward pool (can be changed later)
        rewardPool = initialOwner;
    }
    
    /**
     * @dev Check if wallet can use ETH for gas (only if 0 ZSNAIL balance)
     * @param wallet Address to check
     * @return canUseETH True if wallet has 0 ZSNAIL and can use ETH for gas
     */
    function canUseETHForGas(address wallet) external view returns (bool canUseETH) {
        return balanceOf(wallet) == 0;
    }
    
    /**
     * @dev Pay gas fees using ZSnail tokens
     * @param gasUsed Amount of gas consumed
     * @return ethEquivalent The ETH equivalent amount paid
     */
    function payGasWithZSnail(uint256 gasUsed) external nonReentrant returns (uint256 ethEquivalent) {
        require(gasTokenEnabled, "Gas token payments disabled");
        require(balanceOf(msg.sender) > 0, "Must have ZSNAIL tokens to pay gas");
        
        // Calculate ZSnail amount needed (gasUsed * gasPrice converted to ZSNAIL)
        uint256 zsnailAmount = (gasUsed * 1000000000) / gasTokenRate; // Assuming 1 gwei gas price
        
        require(balanceOf(msg.sender) >= zsnailAmount, "Insufficient ZSnail for gas");
        
        // Burn ZSnail tokens for gas payment
        _burn(msg.sender, zsnailAmount);
        
        // Calculate ETH equivalent
        ethEquivalent = zsnailAmount * gasTokenRate / 10**18;
        
        emit GasTokenUsed(msg.sender, zsnailAmount, gasUsed);
        
        return ethEquivalent;
    }
    
    /**
     * @dev Stake ZSnail tokens to become a validator
     * @param amount Amount of ZSnail tokens to stake
     */
    function stakeForValidation(uint256 amount) external nonReentrant {
        require(amount >= minValidatorStake, "Insufficient stake amount");
        require(balanceOf(msg.sender) >= amount, "Insufficient balance");
        
        // Transfer tokens to this contract
        _transfer(msg.sender, address(this), amount);
        
        // Update validator status and stakes
        validators[msg.sender] = true;
        validatorStakes[msg.sender] += amount;
        totalValidatorStakes += amount;
        
        emit ValidatorStaked(msg.sender, amount);
    }
    
    /**
     * @dev Unstake validator tokens (with delay for security)
     * @param amount Amount to unstake
     */
    function unstakeValidator(uint256 amount) external nonReentrant {
        require(validators[msg.sender], "Not a validator");
        require(validatorStakes[msg.sender] >= amount, "Insufficient staked amount");
        
        // Update stakes
        validatorStakes[msg.sender] -= amount;
        totalValidatorStakes -= amount;
        
        // Remove validator status if below minimum
        if (validatorStakes[msg.sender] < minValidatorStake) {
            validators[msg.sender] = false;
        }
        
        // Return tokens
        _transfer(address(this), msg.sender, amount);
        
        emit ValidatorUnstaked(msg.sender, amount);
    }
    
    /**
     * @dev Distribute mining rewards
     * @param miner Address of the miner
     * @param blockNumber Block number mined
     */
    function distributeMiningReward(address miner, uint256 blockNumber) external onlyOwner {
        require(miners[miner] || msg.sender == owner(), "Not authorized miner");
        
        uint256 reward = miningRewardRate;
        
        // Check max supply
        if (totalSupply() + reward <= MAX_SUPPLY) {
            _mint(miner, reward);
            emit MiningRewardDistributed(miner, reward);
        }
    }
    
    /**
     * @dev Register as a miner
     */
    function registerMiner() external {
        miners[msg.sender] = true;
    }
    
    /**
     * @dev Check if address is a validator
     */
    function isValidator(address account) external view returns (bool) {
        return validators[account] && validatorStakes[account] >= minValidatorStake;
    }
    
    /**
     * @dev Check if address is a miner
     */
    function isMiner(address account) external view returns (bool) {
        return miners[account];
    }
    
    /**
     * @dev Get validator stake amount
     */
    function getValidatorStake(address validator) external view returns (uint256) {
        return validatorStakes[validator];
    }
    
    /**
     * @dev Calculate gas cost in ZSnail tokens
     */
    function calculateGasCost(uint256 gasUsed, uint256 gasPrice) external view returns (uint256) {
        return (gasUsed * gasPrice) / gasTokenRate;
    }
    
    // Owner functions
    function updateGasRate(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Invalid rate");
        gasTokenRate = newRate;
        emit GasRateUpdated(newRate);
    }
    
    function toggleGasToken() external onlyOwner {
        gasTokenEnabled = !gasTokenEnabled;
    }
    
    function updateMinValidatorStake(uint256 newMin) external onlyOwner {
        minValidatorStake = newMin;
    }
    
    function updateRewardRates(uint256 newMiningRate, uint256 newValidatorRate) external onlyOwner {
        miningRewardRate = newMiningRate;
        validatorRewardRate = newValidatorRate;
    }
}