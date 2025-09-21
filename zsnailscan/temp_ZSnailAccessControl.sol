// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ZSnailSecurity.sol";

/**
 * @title ZSnailAccessControl
 * @dev Custom role-based access control for ZSnail L2 blockchain
 * @notice Manages roles and permissions across ZSnail contracts
 */
abstract contract ZSnailAccessControl {
    using ZSnailSecurity for bytes32;
    
    struct RoleData {
        mapping(address => bool) members;
        bytes32 adminRole;
        uint256 memberCount;
    }
    
    mapping(bytes32 => RoleData) private _roles;
    mapping(address => bytes32[]) private _memberRoles;
    
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    
    // Events
    event RoleAdminChanged(bytes32 indexed role, bytes32 indexed previousAdminRole, bytes32 indexed newAdminRole);
    event RoleGranted(bytes32 indexed role, address indexed account, address indexed sender);
    event RoleRevoked(bytes32 indexed role, address indexed account, address indexed sender);
    
    // Custom errors
    error AccessControlUnauthorizedAccount(address account, bytes32 neededRole);
    error AccessControlBadConfirmation();
    
    modifier onlyRole(bytes32 role) {
        _checkRole(role);
        _;
    }
    
    /**
     * @dev Returns true if account has been granted role
     */
    function hasRole(bytes32 role, address account) public view virtual returns (bool) {
        return _roles[role].members[account];
    }
    
    /**
     * @dev Revert with an AccessControlUnauthorizedAccount error if account
     * does not have role. Format of the revert reason is described in _checkRole
     */
    function _checkRole(bytes32 role) internal view virtual {
        _checkRole(role, msg.sender);
    }
    
    /**
     * @dev Revert with an AccessControlUnauthorizedAccount error if account
     * does not have role
     */
    function _checkRole(bytes32 role, address account) internal view virtual {
        if (!hasRole(role, account)) {
            revert AccessControlUnauthorizedAccount(account, role);
        }
    }
    
    /**
     * @dev Returns the admin role that controls role
     */
    function getRoleAdmin(bytes32 role) public view virtual returns (bytes32) {
        return _roles[role].adminRole;
    }
    
    /**
     * @dev Get the number of accounts that have role
     */
    function getRoleMemberCount(bytes32 role) public view virtual returns (uint256) {
        return _roles[role].memberCount;
    }
    
    /**
     * @dev Get all roles for an account
     */
    function getAccountRoles(address account) public view virtual returns (bytes32[] memory) {
        return _memberRoles[account];
    }
    
    /**
     * @dev Grants role to account
     * Requirements:
     * - the caller must have role's admin role
     */
    function grantRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _grantRole(role, account);
    }
    
    /**
     * @dev Revokes role from account
     * Requirements:
     * - the caller must have role's admin role
     */
    function revokeRole(bytes32 role, address account) public virtual onlyRole(getRoleAdmin(role)) {
        _revokeRole(role, account);
    }
    
    /**
     * @dev Revokes role from the calling account
     */
    function renounceRole(bytes32 role, address callerConfirmation) public virtual {
        if (callerConfirmation != msg.sender) {
            revert AccessControlBadConfirmation();
        }
        _revokeRole(role, callerConfirmation);
    }
    
    /**
     * @dev Sets adminRole as role's admin role
     */
    function _setRoleAdmin(bytes32 role, bytes32 adminRole) internal virtual {
        bytes32 previousAdminRole = getRoleAdmin(role);
        _roles[role].adminRole = adminRole;
        emit RoleAdminChanged(role, previousAdminRole, adminRole);
    }
    
    /**
     * @dev Grants role to account
     * Internal function without access restriction
     */
    function _grantRole(bytes32 role, address account) internal virtual {
        if (!hasRole(role, account)) {
            _roles[role].members[account] = true;
            _roles[role].memberCount++;
            _memberRoles[account].push(role);
            emit RoleGranted(role, account, msg.sender);
        }
    }
    
    /**
     * @dev Revokes role from account
     * Internal function without access restriction
     */
    function _revokeRole(bytes32 role, address account) internal virtual {
        if (hasRole(role, account)) {
            _roles[role].members[account] = false;
            _roles[role].memberCount--;
            
            // Remove role from account's roles array
            bytes32[] storage accountRoles = _memberRoles[account];
            for (uint256 i = 0; i < accountRoles.length; i++) {
                if (accountRoles[i] == role) {
                    accountRoles[i] = accountRoles[accountRoles.length - 1];
                    accountRoles.pop();
                    break;
                }
            }
            
            emit RoleRevoked(role, account, msg.sender);
        }
    }
    
    /**
     * @dev Batch grant multiple roles to multiple accounts
     */
    function batchGrantRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external virtual {
        require(roles.length == accounts.length, "ZSnailAccessControl: arrays length mismatch");
        
        for (uint256 i = 0; i < roles.length; i++) {
            grantRole(roles[i], accounts[i]);
        }
    }
    
    /**
     * @dev Batch revoke multiple roles from multiple accounts
     */
    function batchRevokeRoles(
        bytes32[] calldata roles,
        address[] calldata accounts
    ) external virtual {
        require(roles.length == accounts.length, "ZSnailAccessControl: arrays length mismatch");
        
        for (uint256 i = 0; i < roles.length; i++) {
            revokeRole(roles[i], accounts[i]);
        }
    }
    
    /**
     * @dev Check if account has any of the specified roles
     */
    function hasAnyRole(bytes32[] calldata roles, address account) public view virtual returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (hasRole(roles[i], account)) {
                return true;
            }
        }
        return false;
    }
    
    /**
     * @dev Check if account has all of the specified roles
     */
    function hasAllRoles(bytes32[] calldata roles, address account) public view virtual returns (bool) {
        for (uint256 i = 0; i < roles.length; i++) {
            if (!hasRole(roles[i], account)) {
                return false;
            }
        }
        return true;
    }
}