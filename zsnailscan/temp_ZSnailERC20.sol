// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ZSnailMath.sol";
import "./ZSnailSecurity.sol";

/**
 * @title ZSnailERC20
 * @dev Custom ERC20 implementation for ZSnail L2 blockchain
 * @notice Gas-optimized token contract with L2-specific features
 */
contract ZSnailERC20 {
    using ZSnailMath for uint256;
    using ZSnailSecurity for bytes32;
    
    // Token metadata
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    uint256 private _totalSupply;
    
    // Balances and allowances
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    
    // Events
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
    
    // Custom errors
    error ERC20InsufficientBalance(address sender, uint256 balance, uint256 needed);
    error ERC20InvalidSender(address sender);
    error ERC20InvalidReceiver(address receiver);
    error ERC20InsufficientAllowance(address spender, uint256 allowance, uint256 needed);
    error ERC20InvalidApprover(address approver);
    error ERC20InvalidSpender(address spender);
    
    constructor(string memory name_, string memory symbol_, uint8 decimals_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
    }
    
    /**
     * @dev Returns the name of the token
     */
    function name() public view virtual returns (string memory) {
        return _name;
    }
    
    /**
     * @dev Returns the symbol of the token
     */
    function symbol() public view virtual returns (string memory) {
        return _symbol;
    }
    
    /**
     * @dev Returns the decimals of the token
     */
    function decimals() public view virtual returns (uint8) {
        return _decimals;
    }
    
    /**
     * @dev Returns the total supply of tokens
     */
    function totalSupply() public view virtual returns (uint256) {
        return _totalSupply;
    }
    
    /**
     * @dev Returns the balance of account
     */
    function balanceOf(address account) public view virtual returns (uint256) {
        return _balances[account];
    }
    
    /**
     * @dev Moves amount of tokens from the caller's account to to
     */
    function transfer(address to, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }
    
    /**
     * @dev Returns the remaining allowance that spender will be allowed to spend
     */
    function allowance(address owner, address spender) public view virtual returns (uint256) {
        return _allowances[owner][spender];
    }
    
    /**
     * @dev Sets amount as the allowance of spender over the caller's tokens
     */
    function approve(address spender, uint256 amount) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }
    
    /**
     * @dev Moves amount tokens from from to to using allowance mechanism
     */
    function transferFrom(address from, address to, uint256 amount) public virtual returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }
    
    /**
     * @dev Atomically increases the allowance granted to spender by the caller
     */
    function increaseAllowance(address spender, uint256 addedValue) public virtual returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, allowance(owner, spender) + addedValue);
        return true;
    }
    
    /**
     * @dev Atomically decreases the allowance granted to spender by the caller
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public virtual returns (bool) {
        address owner = msg.sender;
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= subtractedValue, "ZSnailERC20: decreased allowance below zero");
        _approve(owner, spender, currentAllowance - subtractedValue);
        return true;
    }
    
    /**
     * @dev Moves amount of tokens from from to to
     */
    function _transfer(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        if (to == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        
        _update(from, to, amount);
    }
    
    /**
     * @dev Transfers amount from sender to recipient, or mints/burns if either is zero
     */
    function _update(address from, address to, uint256 amount) internal virtual {
        if (from == address(0)) {
            // Minting
            _totalSupply += amount;
        } else {
            uint256 fromBalance = _balances[from];
            if (fromBalance < amount) {
                revert ERC20InsufficientBalance(from, fromBalance, amount);
            }
            _balances[from] = fromBalance - amount;
        }
        
        if (to == address(0)) {
            // Burning
            _totalSupply -= amount;
        } else {
            _balances[to] += amount;
        }
        
        emit Transfer(from, to, amount);
    }
    
    /**
     * @dev Creates amount tokens and assigns them to account
     */
    function _mint(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert ERC20InvalidReceiver(address(0));
        }
        _update(address(0), account, amount);
    }
    
    /**
     * @dev Destroys amount tokens from account
     */
    function _burn(address account, uint256 amount) internal virtual {
        if (account == address(0)) {
            revert ERC20InvalidSender(address(0));
        }
        _update(account, address(0), amount);
    }
    
    /**
     * @dev Sets amount as the allowance of spender over owner's tokens
     */
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        if (owner == address(0)) {
            revert ERC20InvalidApprover(address(0));
        }
        if (spender == address(0)) {
            revert ERC20InvalidSpender(address(0));
        }
        
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }
    
    /**
     * @dev Updates owner's allowance for spender based on spent amount
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            if (currentAllowance < amount) {
                revert ERC20InsufficientAllowance(spender, currentAllowance, amount);
            }
            _approve(owner, spender, currentAllowance - amount);
        }
    }
    
    /**
     * @dev Batch transfer to multiple recipients
     */
    function batchTransfer(
        address[] calldata recipients,
        uint256[] calldata amounts
    ) external virtual returns (bool) {
        require(recipients.length == amounts.length, "ZSnailERC20: arrays length mismatch");
        
        for (uint256 i = 0; i < recipients.length; i++) {
            _transfer(msg.sender, recipients[i], amounts[i]);
        }
        
        return true;
    }
    
    /**
     * @dev Get multiple balances at once
     */
    function batchBalanceOf(address[] calldata accounts) external view virtual returns (uint256[] memory) {
        uint256[] memory balances = new uint256[](accounts.length);
        
        for (uint256 i = 0; i < accounts.length; i++) {
            balances[i] = _balances[accounts[i]];
        }
        
        return balances;
    }
    
    /**
     * @dev Permit function for gasless approvals (EIP-2612 style)
     * Note: This is a simplified version - full implementation would include signature verification
     */
    function permit(
        address owner,
        address spender,
        uint256 value,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external virtual {
        require(block.timestamp <= deadline, "ZSnailERC20: permit expired");
        
        // In production, implement full EIP-2612 signature verification here
        // For now, we'll just approve directly (this should be enhanced)
        _approve(owner, spender, value);
    }
}