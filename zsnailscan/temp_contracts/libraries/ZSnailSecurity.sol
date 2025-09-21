// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ZSnailSecurity
 * @dev Custom security library for ZSnail L2 blockchain
 * @notice Provides security functions specific to L2 operations
 */
library ZSnailSecurity {
    
    /**
     * @dev Validates Ethereum address format
     * @param addr Address to validate
     * @return True if address is valid
     */
    function isValidAddress(address addr) internal pure returns (bool) {
        return addr != address(0) && addr != address(0xdead);
    }
    
    /**
     * @dev Validates that caller is not a contract (EOA only)
     * @param caller Address to check
     * @return True if caller is EOA
     */
    function isEOA(address caller) internal view returns (bool) {
        uint256 size;
        assembly {
            size := extcodesize(caller)
        }
        return size == 0;
    }
    
    /**
     * @dev Validates signature for ZSnail L2 transactions
     * @param messageHash Hash of the message
     * @param signature Signature bytes
     * @param signer Expected signer address
     * @return True if signature is valid
     */
    function validateSignature(
        bytes32 messageHash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        require(signature.length == 65, "ZSnailSecurity: invalid signature length");
        
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 32))
            s := mload(add(signature, 64))
            v := byte(0, mload(add(signature, 96)))
        }
        
        if (v < 27) {
            v += 27;
        }
        
        require(v == 27 || v == 28, "ZSnailSecurity: invalid signature v");
        
        address recoveredSigner = ecrecover(messageHash, v, r, s);
        return recoveredSigner == signer && recoveredSigner != address(0);
    }
    
    /**
     * @dev Creates secure hash for ZSnail L2 state commitments
     * @param data Data to hash
     * @param nonce Unique nonce
     * @param blockNumber Current block number
     * @return Secure hash
     */
    function createSecureHash(
        bytes memory data,
        uint256 nonce,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(data, nonce, blockNumber, "ZSnailL2"));
    }
    
    /**
     * @dev Validates Merkle proof for L2 state verification
     * @param proof Merkle proof array
     * @param root Merkle root
     * @param leaf Leaf to verify
     * @return True if proof is valid
     */
    function verifyMerkleProof(
        bytes32[] memory proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;
        
        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }
        
        return computedHash == root;
    }
    
    /**
     * @dev Rate limiting for ZSnail L2 operations
     * @param lastAction Timestamp of last action
     * @param cooldownPeriod Required cooldown period
     * @return True if action is allowed
     */
    function checkRateLimit(uint256 lastAction, uint256 cooldownPeriod) internal view returns (bool) {
        return block.timestamp >= lastAction + cooldownPeriod;
    }
    
    /**
     * @dev Validates gas price is within acceptable range for L2
     * @param gasPrice Proposed gas price
     * @param minGasPrice Minimum allowed gas price
     * @param maxGasPrice Maximum allowed gas price
     * @return True if gas price is valid
     */
    function validateGasPrice(
        uint256 gasPrice,
        uint256 minGasPrice,
        uint256 maxGasPrice
    ) internal pure returns (bool) {
        return gasPrice >= minGasPrice && gasPrice <= maxGasPrice;
    }
    
    /**
     * @dev Emergency pause check for critical functions
     * @param isPaused Current pause state
     * @param caller Address attempting to call function
     * @param emergencyAdmin Emergency admin address
     * @return True if operation should proceed
     */
    function emergencyCheck(
        bool isPaused,
        address caller,
        address emergencyAdmin
    ) internal pure returns (bool) {
        if (isPaused) {
            return caller == emergencyAdmin;
        }
        return true;
    }
}