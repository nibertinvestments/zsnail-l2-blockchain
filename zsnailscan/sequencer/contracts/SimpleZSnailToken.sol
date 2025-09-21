// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Simple ZSnail Token (ZSNAIL)
 * @dev Simplified native gas token for ZSnail L2 Blockchain
 */
contract SimpleZSnailToken {
    
    string public name = "ZSnail Token";
    string public symbol = "ZSNAIL";
    uint8 public decimals = 18;
    
    // Token configuration
    uint256 public constant MAX_SUPPLY = 100_000_000_000 * 10**18;   // 100B tokens max
    uint256 public constant DEPLOYER_ALLOCATION = 10_000_000 * 10**18; // 10M for deployer
    
    uint256 public totalSupply;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;
    
    // Gas mechanics
    uint256 public gasTokenRate = 1000; // 1000 ZSNAIL = 1 ETH equivalent for gas
    bool public gasTokenEnabled = true;
    
    // Validator mechanics
    uint256 public minValidatorStake = 30000 * 10**18; // 30K ZSNAIL minimum
    mapping(address => uint256) public validatorStakes;
    mapping(address => bool) public validators;
    
    address public owner;
    
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    event GasTokenUsed(address indexed user, uint256 amount, uint256 gasUsed);
    event ValidatorStaked(address indexed validator, uint256 amount);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }
    
    constructor(address initialOwner) {
        owner = initialOwner;
        // Mint deployer allocation (10M tokens for gas and operations)
        totalSupply = DEPLOYER_ALLOCATION;
        balanceOf[initialOwner] = DEPLOYER_ALLOCATION;
        emit Transfer(address(0), initialOwner, DEPLOYER_ALLOCATION);
    }
    
    /**
     * @dev Check if wallet can use ETH for gas (only if 0 ZSNAIL balance)
     */
    function canUseETHForGas(address wallet) external view returns (bool) {
        return balanceOf[wallet] == 0;
    }
    
    /**
     * @dev Pay gas fees using ZSnail tokens
     */
    function payGasWithZSnail(uint256 gasUsed) external returns (uint256 ethEquivalent) {
        require(gasTokenEnabled, "Gas token payments disabled");
        require(balanceOf[msg.sender] > 0, "Must have ZSNAIL tokens to pay gas");
        
        uint256 zsnailAmount = (gasUsed * 1000000000) / gasTokenRate;
        require(balanceOf[msg.sender] >= zsnailAmount, "Insufficient ZSnail for gas");
        
        // Burn ZSnail tokens for gas payment
        balanceOf[msg.sender] -= zsnailAmount;
        totalSupply -= zsnailAmount;
        
        ethEquivalent = zsnailAmount * gasTokenRate / 10**18;
        emit GasTokenUsed(msg.sender, zsnailAmount, gasUsed);
        emit Transfer(msg.sender, address(0), zsnailAmount);
        
        return ethEquivalent;
    }
    
    /**
     * @dev Stake tokens to become a validator
     */
    function stakeForValidator() external {
        require(balanceOf[msg.sender] >= minValidatorStake, "Insufficient stake");
        require(!validators[msg.sender], "Already a validator");
        
        validatorStakes[msg.sender] = minValidatorStake;
        validators[msg.sender] = true;
        
        // Transfer stake to contract
        balanceOf[msg.sender] -= minValidatorStake;
        balanceOf[address(this)] += minValidatorStake;
        
        emit ValidatorStaked(msg.sender, minValidatorStake);
        emit Transfer(msg.sender, address(this), minValidatorStake);
    }
    
    /**
     * @dev Mint new tokens (mining rewards)
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(totalSupply + amount <= MAX_SUPPLY, "Exceeds max supply");
        totalSupply += amount;
        balanceOf[to] += amount;
        emit Transfer(address(0), to, amount);
    }
    
    /**
     * @dev Standard ERC20 transfer
     */
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "Insufficient balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }
    
    /**
     * @dev Standard ERC20 approve
     */
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }
    
    /**
     * @dev Standard ERC20 transferFrom
     */
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "Insufficient allowance");
        require(balanceOf[from] >= amount, "Insufficient balance");
        
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        
        emit Transfer(from, to, amount);
        return true;
    }
}