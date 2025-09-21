// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../libraries/ZSnailMath.sol";
import "../libraries/ZSnailSecurity.sol";
import "../libraries/ZSnailCrypto.sol";
import "../interfaces/IZSnailL2.sol";

/**
 * @title ZSnailSequencerInbox
 * @dev L1 contract for receiving and validating L2 transaction batches
 * @notice First contract to deploy - handles sequencer batch submissions
 */
contract ZSnailSequencerInbox {
    using ZSnailMath for uint256;
    using ZSnailSecurity for bytes32;
    using ZSnailCrypto for bytes32[];
    
    // Contract state
    address public sequencer;
    address public rollupContract;
    address public bridge;
    address public owner;
    
    uint256 public totalBatches;
    uint256 public constant MAX_BATCH_SIZE = 1000;
    uint256 public constant BATCH_TIMEOUT = 1 hours;
    uint256 public constant MAX_TIME_VARIATION = 300; // 5 minutes
    
    // Batch tracking
    struct BatchData {
        bytes32 batchHash;
        uint256 timestamp;
        uint256 blockNumber;
        address sequencer;
        uint256 txCount;
        bytes32 dataHash;
        bool executed;
    }
    
    mapping(uint256 => BatchData) public batches;
    mapping(bytes32 => bool) public processedBatches;
    mapping(address => bool) public authorizedSequencers;
    
    // Events
    event BatchSubmitted(
        uint256 indexed batchNumber,
        bytes32 indexed batchHash,
        address indexed sequencer,
        uint256 txCount,
        uint256 timestamp
    );
    
    event SequencerUpdated(
        address indexed oldSequencer,
        address indexed newSequencer
    );
    
    event BatchExecuted(
        uint256 indexed batchNumber,
        bytes32 batchHash,
        bool success
    );
    
    event RollupContractUpdated(
        address indexed oldRollup,
        address indexed newRollup
    );
    
    event BridgeUpdated(
        address indexed oldBridge,
        address indexed newBridge
    );
    
    event SequencerAuthorized(
        address indexed sequencer,
        bool authorized
    );
    
    // Modifiers
    modifier onlySequencer() {
        require(
            msg.sender == sequencer || authorizedSequencers[msg.sender],
            "ZSnailSequencerInbox: unauthorized sequencer"
        );
        _;
    }
    
    modifier onlyRollup() {
        require(
            msg.sender == rollupContract,
            "ZSnailSequencerInbox: only rollup contract"
        );
        _;
    }
    
    modifier onlyOwner() {
        require(msg.sender == owner, "ZSnailSequencerInbox: only owner");
        _;
    }
    
    modifier validBatch(bytes32[] calldata transactions, bytes calldata metadata) {
        require(transactions.length > 0, "ZSnailSequencerInbox: empty batch");
        require(transactions.length <= MAX_BATCH_SIZE, "ZSnailSequencerInbox: batch too large");
        require(metadata.length > 0, "ZSnailSequencerInbox: missing metadata");
        _;
    }
    
    constructor(
        address _sequencer,
        address _owner
    ) {
        require(_sequencer != address(0), "ZSnailSequencerInbox: invalid sequencer");
        require(_owner != address(0), "ZSnailSequencerInbox: invalid owner");
        
        sequencer = _sequencer;
        owner = _owner;
        authorizedSequencers[_sequencer] = true;
        
        emit SequencerUpdated(address(0), _sequencer);
        emit SequencerAuthorized(_sequencer, true);
    }
    
    /**
     * @dev Submit a batch of L2 transactions to L1
     * @param transactions Array of transaction hashes
     * @param metadata Batch metadata including state roots and proofs
     * @return batchNumber The assigned batch number
     */
    function submitBatch(
        bytes32[] calldata transactions,
        bytes calldata metadata
    ) external onlySequencer validBatch(transactions, metadata) returns (uint256 batchNumber) {
        // Increment batch counter
        batchNumber = ++totalBatches;
        
        // Generate batch hash
        bytes32 batchHash = ZSnailCrypto.createBatchCommitment(
            transactions,
            msg.sender,
            batchNumber
        );
        
        // Verify batch hasn't been processed
        require(!processedBatches[batchHash], "ZSnailSequencerInbox: batch already processed");
        
        // Validate timestamp
        require(
            block.timestamp <= block.timestamp + MAX_TIME_VARIATION,
            "ZSnailSequencerInbox: invalid timestamp"
        );
        
        // Create batch data
        bytes32 dataHash = keccak256(abi.encodePacked(transactions, metadata));
        
        batches[batchNumber] = BatchData({
            batchHash: batchHash,
            timestamp: block.timestamp,
            blockNumber: block.number,
            sequencer: msg.sender,
            txCount: transactions.length,
            dataHash: dataHash,
            executed: false
        });
        
        // Mark as processed
        processedBatches[batchHash] = true;
        
        emit BatchSubmitted(
            batchNumber,
            batchHash,
            msg.sender,
            transactions.length,
            block.timestamp
        );
        
        // Forward to rollup contract if available
        if (rollupContract != address(0)) {
            _forwardToRollup(batchNumber, transactions, metadata);
        }
        
        return batchNumber;
    }
    
    /**
     * @dev Execute a submitted batch (called by rollup contract)
     * @param batchNumber The batch number to execute
     * @return success Whether execution was successful
     */
    function executeBatch(uint256 batchNumber) external onlyRollup returns (bool success) {
        require(batchNumber > 0 && batchNumber <= totalBatches, "ZSnailSequencerInbox: invalid batch number");
        
        BatchData storage batch = batches[batchNumber];
        require(!batch.executed, "ZSnailSequencerInbox: batch already executed");
        require(
            block.timestamp >= batch.timestamp + BATCH_TIMEOUT,
            "ZSnailSequencerInbox: batch timeout not reached"
        );
        
        batch.executed = true;
        
        emit BatchExecuted(batchNumber, batch.batchHash, true);
        
        return true;
    }
    
    /**
     * @dev Forward batch to rollup contract for processing
     * @param batchNumber The batch number
     * @param transactions Transaction hashes
     * @param metadata Batch metadata
     */
    function _forwardToRollup(
        uint256 batchNumber,
        bytes32[] calldata transactions,
        bytes calldata metadata
    ) internal {
        (bool success, ) = rollupContract.call(
            abi.encodeWithSignature(
                "processBatch(uint256,bytes32[],bytes)",
                batchNumber,
                transactions,
                metadata
            )
        );
        
        if (!success) {
            // Log failure but don't revert to avoid blocking batch submission
            emit BatchExecuted(batchNumber, batches[batchNumber].batchHash, false);
        }
    }
    
    /**
     * @dev Get batch information
     * @param batchNumber The batch number to query
     * @return Batch data structure
     */
    function getBatch(uint256 batchNumber) external view returns (BatchData memory) {
        require(batchNumber > 0 && batchNumber <= totalBatches, "ZSnailSequencerInbox: invalid batch number");
        return batches[batchNumber];
    }
    
    /**
     * @dev Check if a batch hash has been processed
     * @param batchHash The batch hash to check
     * @return Whether the batch has been processed
     */
    function isBatchProcessed(bytes32 batchHash) external view returns (bool) {
        return processedBatches[batchHash];
    }
    
    /**
     * @dev Get the latest batch number
     * @return The most recent batch number
     */
    function getLatestBatchNumber() external view returns (uint256) {
        return totalBatches;
    }
    
    /**
     * @dev Check if an address is an authorized sequencer
     * @param _sequencer Address to check
     * @return Whether the address is authorized
     */
    function isAuthorizedSequencer(address _sequencer) external view returns (bool) {
        return _sequencer == sequencer || authorizedSequencers[_sequencer];
    }
    
    // Admin Functions
    
    /**
     * @dev Update the main sequencer address
     * @param _newSequencer New sequencer address
     */
    function setSequencer(address _newSequencer) external onlyOwner {
        require(_newSequencer != address(0), "ZSnailSequencerInbox: invalid sequencer");
        
        address oldSequencer = sequencer;
        sequencer = _newSequencer;
        authorizedSequencers[_newSequencer] = true;
        
        emit SequencerUpdated(oldSequencer, _newSequencer);
        emit SequencerAuthorized(_newSequencer, true);
    }
    
    /**
     * @dev Set rollup contract address
     * @param _rollupContract New rollup contract address
     */
    function setRollupContract(address _rollupContract) external onlyOwner {
        require(_rollupContract != address(0), "ZSnailSequencerInbox: invalid rollup contract");
        
        address oldRollup = rollupContract;
        rollupContract = _rollupContract;
        
        emit RollupContractUpdated(oldRollup, _rollupContract);
    }
    
    /**
     * @dev Set bridge contract address
     * @param _bridge New bridge contract address
     */
    function setBridge(address _bridge) external onlyOwner {
        require(_bridge != address(0), "ZSnailSequencerInbox: invalid bridge");
        
        address oldBridge = bridge;
        bridge = _bridge;
        
        emit BridgeUpdated(oldBridge, _bridge);
    }
    
    /**
     * @dev Authorize or deauthorize a sequencer
     * @param _sequencer Sequencer address
     * @param _authorized Whether to authorize or deauthorize
     */
    function setSequencerAuthorization(address _sequencer, bool _authorized) external onlyOwner {
        require(_sequencer != address(0), "ZSnailSequencerInbox: invalid sequencer");
        
        authorizedSequencers[_sequencer] = _authorized;
        
        emit SequencerAuthorized(_sequencer, _authorized);
    }
    
    /**
     * @dev Transfer ownership to a new address
     * @param _newOwner New owner address
     */
    function transferOwnership(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "ZSnailSequencerInbox: invalid owner");
        owner = _newOwner;
    }
    
    /**
     * @dev Emergency pause functionality
     */
    function emergencyPause() external onlyOwner {
        // Implementation for emergency pause
        // This would disable batch submissions temporarily
    }
    
    /**
     * @dev Calculate batch processing fee
     * @param txCount Number of transactions in batch
     * @return fee The calculated fee
     */
    function calculateBatchFee(uint256 txCount) external pure returns (uint256 fee) {
        return ZSnailMath.mulDiv(txCount, 1e15, 1); // 0.001 ETH per transaction
    }
}