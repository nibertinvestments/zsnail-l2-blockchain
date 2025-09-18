// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ZSnailOwnable
 * @dev Custom ownership contract for ZSnail L2 blockchain
 * @notice Provides basic authorization control functions
 */
abstract contract ZSnailOwnable {
    
    address private _owner;
    address private _pendingOwner;
    
    // Events
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event OwnershipTransferStarted(address indexed previousOwner, address indexed newOwner);
    
    // Custom errors
    error OwnableUnauthorizedAccount(address account);
    error OwnableInvalidOwner(address owner);
    
    modifier onlyOwner() {
        _checkOwner();
        _;
    }
    
    constructor(address initialOwner) {
        if (initialOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _transferOwnership(initialOwner);
    }
    
    /**
     * @dev Returns the address of the current owner
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }
    
    /**
     * @dev Returns the address of the pending owner
     */
    function pendingOwner() public view virtual returns (address) {
        return _pendingOwner;
    }
    
    /**
     * @dev Throws if the sender is not the owner
     */
    function _checkOwner() internal view virtual {
        if (owner() != msg.sender) {
            revert OwnableUnauthorizedAccount(msg.sender);
        }
    }
    
    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }
    
    /**
     * @dev Starts the ownership transfer of the contract to a new account
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        if (newOwner == address(0)) {
            revert OwnableInvalidOwner(address(0));
        }
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }
    
    /**
     * @dev The new owner accepts the ownership transfer
     */
    function acceptOwnership() public virtual {
        address sender = msg.sender;
        if (pendingOwner() != sender) {
            revert OwnableUnauthorizedAccount(sender);
        }
        _transferOwnership(sender);
    }
    
    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`)
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        _pendingOwner = address(0);
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}