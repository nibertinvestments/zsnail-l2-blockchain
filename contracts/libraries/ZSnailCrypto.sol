// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ZSnailCrypto
 * @dev Custom cryptographic library for ZSnail L2 blockchain
 * @notice Provides optimized cryptographic functions for L2 operations
 */
library ZSnailCrypto {
    
    /**
     * @dev Generate deterministic hash for L2 block headers
     * @param parentHash Hash of parent block
     * @param stateRoot Root of state tree
     * @param txRoot Root of transaction tree
     * @param timestamp Block timestamp
     * @param blockNumber Block number
     * @return Block hash
     */
    function generateBlockHash(
        bytes32 parentHash,
        bytes32 stateRoot,
        bytes32 txRoot,
        uint256 timestamp,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            parentHash,
            stateRoot,
            txRoot,
            timestamp,
            blockNumber,
            "ZSnailL2Block"
        ));
    }
    
    /**
     * @dev Generate transaction hash for L2 transactions
     * @param from Sender address
     * @param to Recipient address
     * @param value Transfer value
     * @param data Transaction data
     * @param nonce Transaction nonce
     * @param gasPrice Gas price
     * @param gasLimit Gas limit
     * @return Transaction hash
     */
    function generateTxHash(
        address from,
        address to,
        uint256 value,
        bytes memory data,
        uint256 nonce,
        uint256 gasPrice,
        uint256 gasLimit
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            from,
            to,
            value,
            data,
            nonce,
            gasPrice,
            gasLimit,
            "ZSnailL2Tx"
        ));
    }
    
    /**
     * @dev Create commitment hash for fraud proofs
     * @param stateRoot L2 state root
     * @param blockNumber Block number being committed
     * @param batchIndex Index of transaction batch
     * @return Commitment hash
     */
    function createCommitment(
        bytes32 stateRoot,
        uint256 blockNumber,
        uint256 batchIndex
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            stateRoot,
            blockNumber,
            batchIndex,
            block.timestamp,
            "ZSnailCommitment"
        ));
    }
    
    /**
     * @dev Generate withdrawal proof hash
     * @param recipient Withdrawal recipient
     * @param amount Withdrawal amount
     * @param l2TxHash L2 transaction hash
     * @param blockNumber L2 block number
     * @return Withdrawal proof hash
     */
    function generateWithdrawalProof(
        address recipient,
        uint256 amount,
        bytes32 l2TxHash,
        uint256 blockNumber
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            recipient,
            amount,
            l2TxHash,
            blockNumber,
            "ZSnailWithdrawal"
        ));
    }
    
    /**
     * @dev Create challenge hash for fraud proof disputes
     * @param challenger Address of challenger
     * @param assertionHash Hash of disputed assertion
     * @param challengeData Challenge evidence data
     * @return Challenge hash
     */
    function createChallengeHash(
        address challenger,
        bytes32 assertionHash,
        bytes memory challengeData
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            challenger,
            assertionHash,
            challengeData,
            block.timestamp,
            "ZSnailChallenge"
        ));
    }
    
    /**
     * @dev Generate unique validator ID
     * @param validatorAddress Validator's address
     * @param stakingAmount Amount staked
     * @param registrationTime Time of registration
     * @return Unique validator ID
     */
    function generateValidatorId(
        address validatorAddress,
        uint256 stakingAmount,
        uint256 registrationTime
    ) internal pure returns (bytes32) {
        return keccak256(abi.encodePacked(
            validatorAddress,
            stakingAmount,
            registrationTime,
            "ZSnailValidator"
        ));
    }
    
    /**
     * @dev Create batch commitment for sequencer operations
     * @param transactions Array of transaction hashes
     * @param sequencer Sequencer address
     * @param batchNumber Sequential batch number
     * @return Batch commitment hash
     */
    function createBatchCommitment(
        bytes32[] memory transactions,
        address sequencer,
        uint256 batchNumber
    ) internal pure returns (bytes32) {
        bytes32 txRoot = computeMerkleRoot(transactions);
        
        return keccak256(abi.encodePacked(
            txRoot,
            sequencer,
            batchNumber,
            block.timestamp,
            "ZSnailBatch"
        ));
    }
    
    /**
     * @dev Compute Merkle root from array of hashes
     * @param hashes Array of hashes to compute root for
     * @return Merkle root
     */
    function computeMerkleRoot(bytes32[] memory hashes) internal pure returns (bytes32) {
        require(hashes.length > 0, "ZSnailCrypto: empty hash array");
        
        if (hashes.length == 1) {
            return hashes[0];
        }
        
        uint256 length = hashes.length;
        bytes32[] memory nextLevel = new bytes32[]((length + 1) / 2);
        
        for (uint256 i = 0; i < length; i += 2) {
            if (i + 1 < length) {
                nextLevel[i / 2] = keccak256(abi.encodePacked(hashes[i], hashes[i + 1]));
            } else {
                nextLevel[i / 2] = hashes[i];
            }
        }
        
        return computeMerkleRoot(nextLevel);
    }
    
    /**
     * @dev Generate unique bridge transfer ID
     * @param from Source address
     * @param to Destination address
     * @param amount Transfer amount
     * @param isL1ToL2 Direction of transfer
     * @return Unique transfer ID
     */
    function generateBridgeTransferId(
        address from,
        address to,
        uint256 amount,
        bool isL1ToL2
    ) internal view returns (bytes32) {
        return keccak256(abi.encodePacked(
            from,
            to,
            amount,
            isL1ToL2,
            block.timestamp,
            block.number,
            "ZSnailBridge"
        ));
    }
}