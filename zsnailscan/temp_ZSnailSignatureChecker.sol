// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ZSnailSignatureChecker
 * @dev Signature verification utilities for ZSnail L2 blockchain
 * @notice Gas-optimized signature checking with multiple format support
 */
library ZSnailSignatureChecker {
    
    // Custom errors
    error ZSnailSignatureChecker__InvalidSignatureLength();
    error ZSnailSignatureChecker__InvalidSignatureS();
    error ZSnailSignatureChecker__InvalidSignatureV();
    error ZSnailSignatureChecker__ECRecoverFailed();
    error ZSnailSignatureChecker__InvalidContractSignature();
    
    // EIP-1271 magic value
    bytes4 constant internal MAGICVALUE = 0x1626ba7e;
    
    /**
     * @dev Checks if a signature is valid for a given signer and hash
     * @param hash Hash that was signed
     * @param signature Signature to verify
     * @param signer Expected signer address
     * @return true if signature is valid
     */
    function isValidSignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        // Check if signer is a contract
        if (signer.code.length > 0) {
            return isValidContractSignature(hash, signature, signer);
        } else {
            return isValidEOASignature(hash, signature, signer);
        }
    }
    
    /**
     * @dev Verify EOA (Externally Owned Account) signature
     * @param hash Hash that was signed
     * @param signature Signature to verify
     * @param signer Expected signer address
     * @return true if signature is valid
     */
    function isValidEOASignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal pure returns (bool) {
        address recovered = recoverSigner(hash, signature);
        return recovered == signer;
    }
    
    /**
     * @dev Verify contract signature using EIP-1271
     * @param hash Hash that was signed
     * @param signature Signature to verify
     * @param signer Contract address
     * @return true if signature is valid
     */
    function isValidContractSignature(
        bytes32 hash,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        try IERC1271(signer).isValidSignature(hash, signature) returns (bytes4 magicValue) {
            return magicValue == MAGICVALUE;
        } catch {
            return false;
        }
    }
    
    /**
     * @dev Recover signer address from hash and signature
     * @param hash Hash that was signed
     * @param signature Signature bytes
     * @return Recovered signer address
     */
    function recoverSigner(bytes32 hash, bytes memory signature) internal pure returns (address) {
        if (signature.length == 65) {
            return recoverSignerFromComponents(hash, signature);
        } else if (signature.length == 64) {
            // Compact signature format
            return recoverSignerCompact(hash, signature);
        } else {
            revert ZSnailSignatureChecker__InvalidSignatureLength();
        }
    }
    
    /**
     * @dev Recover signer from signature components (r, s, v)
     * @param hash Hash that was signed
     * @param signature 65-byte signature (r + s + v)
     * @return Recovered signer address
     */
    function recoverSignerFromComponents(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 s;
        uint8 v;
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        return recoverSigner(hash, v, r, s);
    }
    
    /**
     * @dev Recover signer from compact signature (64 bytes)
     * @param hash Hash that was signed
     * @param signature 64-byte compact signature
     * @return Recovered signer address
     */
    function recoverSignerCompact(bytes32 hash, bytes memory signature) internal pure returns (address) {
        bytes32 r;
        bytes32 vs;
        
        assembly {
            r := mload(add(signature, 0x20))
            vs := mload(add(signature, 0x40))
        }
        
        return recoverSignerFromVS(hash, r, vs);
    }
    
    /**
     * @dev Recover signer using r and vs components
     * @param hash Hash that was signed
     * @param r R component
     * @param vs VS component (s with recovery bit)
     * @return Recovered signer address
     */
    function recoverSignerFromVS(bytes32 hash, bytes32 r, bytes32 vs) internal pure returns (address) {
        bytes32 s = vs & 0x7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff;
        uint8 v = uint8((uint256(vs) >> 255) + 27);
        
        return recoverSigner(hash, v, r, s);
    }
    
    /**
     * @dev Recover signer from individual components
     * @param hash Hash that was signed
     * @param v Recovery parameter
     * @param r R component
     * @param s S component
     * @return Recovered signer address
     */
    function recoverSigner(
        bytes32 hash,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) internal pure returns (address) {
        // Validate signature parameters
        if (uint256(s) > 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0) {
            revert ZSnailSignatureChecker__InvalidSignatureS();
        }
        
        if (v != 27 && v != 28) {
            revert ZSnailSignatureChecker__InvalidSignatureV();
        }
        
        address signer = ecrecover(hash, v, r, s);
        if (signer == address(0)) {
            revert ZSnailSignatureChecker__ECRecoverFailed();
        }
        
        return signer;
    }
    
    /**
     * @dev Create Ethereum Signed Message hash
     * @param message Original message
     * @return Hash with Ethereum prefix
     */
    function toEthSignedMessageHash(bytes32 message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", message));
    }
    
    /**
     * @dev Create Ethereum Signed Message hash for arbitrary data
     * @param message Original message bytes
     * @return Hash with Ethereum prefix
     */
    function toEthSignedMessageHash(bytes memory message) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            "\x19Ethereum Signed Message:\n",
            _toString(message.length),
            message
        ));
    }
    
    /**
     * @dev Create typed data hash (EIP-712)
     * @param domainSeparator Domain separator
     * @param structHash Struct hash
     * @return Typed data hash
     */
    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
    }
    
    /**
     * @dev Verify multiple signatures for the same hash
     * @param hash Hash that was signed
     * @param signatures Array of signatures
     * @param signers Array of expected signers
     * @return Array of verification results
     */
    function verifyMultipleSignatures(
        bytes32 hash,
        bytes[] memory signatures,
        address[] memory signers
    ) internal view returns (bool[] memory) {
        require(signatures.length == signers.length, "ZSnailSignatureChecker: array length mismatch");
        
        bool[] memory results = new bool[](signatures.length);
        
        for (uint256 i = 0; i < signatures.length; i++) {
            results[i] = isValidSignature(hash, signatures[i], signers[i]);
        }
        
        return results;
    }
    
    /**
     * @dev Check if threshold of signatures is met
     * @param hash Hash that was signed
     * @param signatures Array of signatures
     * @param signers Array of expected signers
     * @param threshold Minimum number of valid signatures required
     * @return true if threshold is met
     */
    function checkSignatureThreshold(
        bytes32 hash,
        bytes[] memory signatures,
        address[] memory signers,
        uint256 threshold
    ) internal view returns (bool) {
        require(signatures.length == signers.length, "ZSnailSignatureChecker: array length mismatch");
        require(threshold <= signatures.length, "ZSnailSignatureChecker: threshold too high");
        
        uint256 validSignatures = 0;
        
        for (uint256 i = 0; i < signatures.length; i++) {
            if (isValidSignature(hash, signatures[i], signers[i])) {
                validSignatures++;
                if (validSignatures >= threshold) {
                    return true;
                }
            }
        }
        
        return false;
    }
    
    /**
     * @dev Verify signature with nonce to prevent replay attacks
     * @param hash Original hash
     * @param nonce Nonce value
     * @param signature Signature to verify
     * @param signer Expected signer
     * @return true if signature is valid
     */
    function verifySignatureWithNonce(
        bytes32 hash,
        uint256 nonce,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        bytes32 nonceHash = keccak256(abi.encodePacked(hash, nonce));
        return isValidSignature(nonceHash, signature, signer);
    }
    
    /**
     * @dev Verify signature with expiration timestamp
     * @param hash Original hash
     * @param expiration Expiration timestamp
     * @param signature Signature to verify
     * @param signer Expected signer
     * @return true if signature is valid and not expired
     */
    function verifySignatureWithExpiration(
        bytes32 hash,
        uint256 expiration,
        bytes memory signature,
        address signer
    ) internal view returns (bool) {
        if (block.timestamp > expiration) {
            return false;
        }
        
        bytes32 expirationHash = keccak256(abi.encodePacked(hash, expiration));
        return isValidSignature(expirationHash, signature, signer);
    }
    
    /**
     * @dev Split signature into components
     * @param signature Signature bytes
     * @return v Recovery parameter
     * @return r R component
     * @return s S component
     */
    function splitSignature(bytes memory signature) internal pure returns (uint8 v, bytes32 r, bytes32 s) {
        if (signature.length != 65) {
            revert ZSnailSignatureChecker__InvalidSignatureLength();
        }
        
        assembly {
            r := mload(add(signature, 0x20))
            s := mload(add(signature, 0x40))
            v := byte(0, mload(add(signature, 0x60)))
        }
        
        return (v, r, s);
    }
    
    /**
     * @dev Combine signature components into bytes
     * @param v Recovery parameter
     * @param r R component
     * @param s S component
     * @return Combined signature bytes
     */
    function combineSignature(uint8 v, bytes32 r, bytes32 s) internal pure returns (bytes memory) {
        return abi.encodePacked(r, s, v);
    }
    
    /**
     * @dev Check if signature uses canonical form (EIP-2)
     * @param signature Signature to check
     * @return true if signature is canonical
     */
    function isCanonicalSignature(bytes memory signature) internal pure returns (bool) {
        if (signature.length != 65) {
            return false;
        }
        
        bytes32 s;
        assembly {
            s := mload(add(signature, 0x40))
        }
        
        return uint256(s) <= 0x7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0;
    }
    
    /**
     * @dev Convert uint256 to string
     * @param value Value to convert
     * @return String representation
     */
    function _toString(uint256 value) private pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        
        uint256 temp = value;
        uint256 digits;
        
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        
        bytes memory buffer = new bytes(digits);
        
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        
        return string(buffer);
    }
    
    /**
     * @dev Hash message with domain separator for EIP-712
     * @param domainSeparator Domain separator
     * @param message Message to hash
     * @return Hash for signing
     */
    function hashWithDomain(bytes32 domainSeparator, bytes memory message) internal pure returns (bytes32) {
        bytes32 messageHash = keccak256(message);
        return toTypedDataHash(domainSeparator, messageHash);
    }
    
    /**
     * @dev Verify batch of signatures with same hash efficiently
     * @param hash Hash that was signed
     * @param signatures Concatenated signatures (65 bytes each)
     * @param signers Array of expected signers
     * @return Number of valid signatures
     */
    function verifyBatchSignatures(
        bytes32 hash,
        bytes memory signatures,
        address[] memory signers
    ) internal view returns (uint256) {
        require(signatures.length == signers.length * 65, "ZSnailSignatureChecker: invalid signatures length");
        
        uint256 validCount = 0;
        
        for (uint256 i = 0; i < signers.length; i++) {
            bytes memory signature = new bytes(65);
            
            // Extract signature
            for (uint256 j = 0; j < 65; j++) {
                signature[j] = signatures[i * 65 + j];
            }
            
            if (isValidSignature(hash, signature, signers[i])) {
                validCount++;
            }
        }
        
        return validCount;
    }
}

/**
 * @dev Interface for EIP-1271 signature validation
 */
interface IERC1271 {
    function isValidSignature(bytes32 hash, bytes memory signature) external view returns (bytes4 magicValue);
}