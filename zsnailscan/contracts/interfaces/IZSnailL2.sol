// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IZSnailL2
 * @dev Core interface for ZSnail L2 blockchain operations
 * @notice Defines standard interactions for L2 rollup functionality
 */
interface IZSnailL2 {
    
    // Events
    event L2BlockCreated(
        uint256 indexed blockNumber,
        bytes32 indexed blockHash,
        bytes32 stateRoot,
        uint256 timestamp
    );
    
    event TransactionExecuted(
        bytes32 indexed txHash,
        address indexed from,
        address indexed to,
        uint256 value,
        bool success
    );
    
    event StateCommitted(
        uint256 indexed blockNumber,
        bytes32 stateRoot,
        bytes32 commitment
    );
    
    event ChallengeCreated(
        bytes32 indexed challengeId,
        address indexed challenger,
        bytes32 assertionHash
    );
    
    event ChallengeResolved(
        bytes32 indexed challengeId,
        bool successful,
        address winner
    );
    
    event ValidatorRegistered(
        address indexed validator,
        bytes32 validatorId,
        uint256 stake
    );
    
    event BatchSubmitted(
        uint256 indexed batchNumber,
        bytes32 batchHash,
        address indexed sequencer,
        uint256 txCount
    );
    
    event WithdrawalInitiated(
        address indexed recipient,
        uint256 amount,
        bytes32 withdrawalId
    );
    
    event BridgeTransfer(
        bytes32 indexed transferId,
        address indexed from,
        address indexed to,
        uint256 amount,
        bool isL1ToL2
    );
    
    // Core L2 Functions
    function submitBatch(
        bytes32[] calldata transactions,
        bytes32 stateRoot,
        bytes calldata proof
    ) external returns (bytes32 batchHash);
    
    function createChallenge(
        bytes32 assertionHash,
        bytes calldata challengeData
    ) external returns (bytes32 challengeId);
    
    function resolveChallenge(
        bytes32 challengeId,
        bytes calldata resolution
    ) external returns (bool success);
    
    function commitState(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata proof
    ) external returns (bytes32 commitment);
    
    function executeTransaction(
        address to,
        uint256 value,
        bytes calldata data,
        uint256 gasLimit
    ) external payable returns (bool success, bytes memory returnData);
    
    // Validator Functions
    function registerValidator(
        bytes calldata validatorData
    ) external payable returns (bytes32 validatorId);
    
    function stake(
        uint256 amount
    ) external payable;
    
    function unstake(
        uint256 amount
    ) external;
    
    function slashValidator(
        address validator,
        uint256 amount,
        bytes calldata evidence
    ) external;
    
    // Bridge Functions
    function initiateBridgeTransfer(
        address to,
        uint256 amount,
        bool isL1ToL2,
        bytes calldata data
    ) external payable returns (bytes32 transferId);
    
    function completeBridgeTransfer(
        bytes32 transferId,
        bytes calldata proof
    ) external;
    
    function initiateWithdrawal(
        uint256 amount,
        address recipient
    ) external returns (bytes32 withdrawalId);
    
    function finalizeWithdrawal(
        bytes32 withdrawalId,
        bytes calldata proof
    ) external;
    
    // State Query Functions
    function getLatestBlockNumber() external view returns (uint256);
    
    function getBlockHash(uint256 blockNumber) external view returns (bytes32);
    
    function getStateRoot(uint256 blockNumber) external view returns (bytes32);
    
    function getTransactionStatus(
        bytes32 txHash
    ) external view returns (bool executed, bool success);
    
    function getValidatorInfo(
        address validator
    ) external view returns (
        bytes32 validatorId,
        uint256 stake,
        bool active,
        uint256 registerTime
    );
    
    function getBatchInfo(
        uint256 batchNumber
    ) external view returns (
        bytes32 batchHash,
        address sequencer,
        uint256 txCount,
        uint256 timestamp
    );
    
    function getChallengeInfo(
        bytes32 challengeId
    ) external view returns (
        address challenger,
        bytes32 assertionHash,
        bool resolved,
        address winner
    );
    
    function getWithdrawalInfo(
        bytes32 withdrawalId
    ) external view returns (
        address recipient,
        uint256 amount,
        bool completed,
        uint256 timestamp
    );
    
    // Configuration Functions
    function updateSequencer(address newSequencer) external;
    
    function updateChallengeWindow(uint256 newWindow) external;
    
    function updateMinStake(uint256 newMinStake) external;
    
    function emergencyPause() external;
    
    function emergencyUnpause() external;
    
    // Fee Functions
    function calculateGasFee(
        uint256 gasUsed,
        uint256 gasPrice
    ) external view returns (uint256 fee);
    
    function updateBaseFee(uint256 newBaseFee) external;
    
    function getBaseFee() external view returns (uint256);
}

/**
 * @title IZSnailSequencer
 * @dev Interface for ZSnail L2 sequencer operations
 */
interface IZSnailSequencer {
    
    event SequencerUpdated(address indexed oldSequencer, address indexed newSequencer);
    event BatchOrdered(uint256 indexed batchNumber, bytes32 batchHash);
    
    function orderBatch(
        bytes32[] calldata transactions,
        uint256 timestamp
    ) external returns (uint256 batchNumber);
    
    function getNextBatchNumber() external view returns (uint256);
    
    function isAuthorizedSequencer(address sequencer) external view returns (bool);
}

/**
 * @title IZSnailValidator
 * @dev Interface for ZSnail L2 validator operations
 */
interface IZSnailValidator {
    
    event ValidationSubmitted(
        bytes32 indexed validationHash,
        address indexed validator,
        uint256 blockNumber
    );
    
    function submitValidation(
        uint256 blockNumber,
        bytes32 stateRoot,
        bytes calldata proof
    ) external returns (bytes32 validationHash);
    
    function isActiveValidator(address validator) external view returns (bool);
    
    function getValidatorStake(address validator) external view returns (uint256);
}

/**
 * @title IZSnailBridge
 * @dev Interface for ZSnail L1/L2 bridge operations
 */
interface IZSnailBridge {
    
    event DepositInitiated(
        address indexed from,
        address indexed to,
        uint256 amount,
        bytes32 transferId
    );
    
    event WithdrawalFinalized(
        address indexed recipient,
        uint256 amount,
        bytes32 withdrawalId
    );
    
    function deposit(
        address to,
        bytes calldata data
    ) external payable returns (bytes32 transferId);
    
    function withdraw(
        uint256 amount,
        address recipient,
        bytes calldata proof
    ) external;
    
    function isValidProof(bytes calldata proof) external view returns (bool);
}