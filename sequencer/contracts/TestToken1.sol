// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title Test Token 1 (TT1)
 * @dev ERC20 token with burnable and ownable features
 * @dev Initial supply: 10,000 tokens minted to the deployer
 */
contract TestToken1 is ERC20, ERC20Burnable, Ownable {
    
    /**
     * @dev Constructor that mints 10,000 tokens to the deployer
     * @param initialOwner The address that will own the contract and receive initial tokens
     */
    constructor(address initialOwner) 
        ERC20("Test Token 1", "TT1") 
        Ownable(initialOwner)
    {
        // Mint 10,000 tokens (with 18 decimals) to the initial owner
        _mint(initialOwner, 10000 * 10**decimals());
    }

    /**
     * @dev Mint new tokens (only owner can call this)
     * @param to The address to receive the new tokens
     * @param amount The amount of tokens to mint (in wei units)
     */
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount);
    }

    /**
     * @dev Get the total supply in human-readable format
     * @return The total supply divided by 10^decimals
     */
    function totalSupplyFormatted() public view returns (uint256) {
        return totalSupply() / 10**decimals();
    }

    /**
     * @dev Get the balance of an account in human-readable format
     * @param account The address to check
     * @return The balance divided by 10^decimals
     */
    function balanceOfFormatted(address account) public view returns (uint256) {
        return balanceOf(account) / 10**decimals();
    }

    /**
     * @dev Burn tokens from the caller's account (inherited from ERC20Burnable)
     * @param amount The amount of tokens to burn (in wei units)
     */
    // burn function is inherited from ERC20Burnable

    /**
     * @dev Burn tokens from another account (requires allowance)
     * @param account The account to burn tokens from
     * @param amount The amount of tokens to burn (in wei units)
     */
    // burnFrom function is inherited from ERC20Burnable
}