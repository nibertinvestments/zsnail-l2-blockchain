import { ethers } from 'ethers';
import { logger } from './logger';
import { SequencerService } from '../services/SequencerService';
import { ValidatorService } from '../services/ValidatorService';
import { BridgeService } from '../services/BridgeService';
import { StateManager } from './StateManager';
import { TransactionPool } from './TransactionPool';

export interface ZSnailL2Config {
  chainId: number;
  l1RpcUrl: string;
  l1WsUrl: string;
  rollupContractAddress?: string;
  bridgeContractAddress?: string;
}

export interface NodeStatus {
  isRunning: boolean;
  blockHeight: number;
  pendingTransactions: number;
  lastL1Sync: number;
  sequencerStatus: string;
  validatorStatus: string;
}

export class ZSnailL2Node {
  private config: ZSnailL2Config;
  private l1Provider: ethers.JsonRpcProvider;
  private l1WsProvider: ethers.WebSocketProvider;
  private isInitialized = false;
  private isRunning = false;

  // Core L2 Services - All custom implementations
  private sequencer: SequencerService;
  private validator: ValidatorService;
  private bridge: BridgeService;
  private stateManager: StateManager;
  private transactionPool: TransactionPool;

  // Block and transaction tracking
  private currentBlockHeight = 0;
  private lastL1SyncBlock = 0;

  constructor(config: ZSnailL2Config) {
    this.config = config;
    
    // Initialize L1 providers for mainnet connection
    this.l1Provider = new ethers.JsonRpcProvider(config.l1RpcUrl);
    this.l1WsProvider = new ethers.WebSocketProvider(config.l1WsUrl);
    
    logger.info('🔧 ZSnail L2 Node configured:', {
      chainId: config.chainId,
      l1Connected: true,
      customContracts: !config.rollupContractAddress ? 'pending' : 'configured'
    });
  }

  async initialize(): Promise<void> {
    if (this.isInitialized) {
      logger.warn('⚠️ ZSnail L2 Node already initialized');
      return;
    }

    try {
      logger.info('🚀 Starting ZSnail L2 Node initialization...');

      // Initialize core L2 components
      await this.initializeL1Connection();
      await this.initializeCoreServices();
      await this.initializeCustomContracts();
      
      this.isInitialized = true;
      this.isRunning = true;
      
      logger.info('✅ ZSnail L2 Node initialization complete');
    } catch (error) {
      logger.error('❌ ZSnail L2 Node initialization failed:', error);
      throw error;
    }
  }

  private async initializeL1Connection(): Promise<void> {
    try {
      // Test L1 mainnet connection
      const network = await this.l1Provider.getNetwork();
      const blockNumber = await this.l1Provider.getBlockNumber();
      
      logger.info('🔗 L1 Mainnet connection established:', {
        chainId: network.chainId.toString(),
        blockNumber,
        provider: 'Infura'
      });

      this.lastL1SyncBlock = blockNumber;
    } catch (error) {
      logger.error('❌ Failed to connect to L1 mainnet:', error);
      throw new Error('L1 connection required for ZSnail L2 operation');
    }
  }

  private async initializeCoreServices(): Promise<void> {
    logger.info('🔧 Initializing ZSnail L2 core services...');

    // Initialize custom state management
    this.stateManager = new StateManager({
      chainId: this.config.chainId,
      l1Provider: this.l1Provider
    });

    // Initialize custom transaction pool
    this.transactionPool = new TransactionPool({
      maxPoolSize: 10000,
      gasLimit: 15000000
    });

    // Initialize custom sequencer service
    this.sequencer = new SequencerService({
      stateManager: this.stateManager,
      transactionPool: this.transactionPool,
      batchSize: 100,
      batchTimeoutMs: 5000
    });

    // Initialize custom validator service
    this.validator = new ValidatorService({
      stateManager: this.stateManager,
      l1Provider: this.l1Provider,
      fraudProofWindow: 7 * 24 * 60 * 60 // 7 days
    });

    // Initialize custom bridge service
    this.bridge = new BridgeService({
      l1Provider: this.l1Provider,
      l1WsProvider: this.l1WsProvider,
      stateManager: this.stateManager
    });

    logger.info('✅ ZSnail L2 core services initialized');
  }

  private async initializeCustomContracts(): Promise<void> {
    // Only initialize contracts if addresses are provided
    if (!this.config.rollupContractAddress) {
      logger.info('📝 Custom contracts not deployed yet - running in development mode');
      return;
    }

    logger.info('📜 Initializing custom ZSnail contracts...');
    
    // Initialize our custom rollup contract interaction
    await this.bridge.initializeCustomContracts({
      rollupAddress: this.config.rollupContractAddress!,
      bridgeAddress: this.config.bridgeContractAddress!
    });

    logger.info('✅ Custom ZSnail contracts initialized');
  }

  // Public API methods for the REST endpoints
  async submitTransaction(transaction: any): Promise<string> {
    if (!this.isRunning) {
      throw new Error('ZSnail L2 Node not running');
    }

    return await this.transactionPool.addTransaction(transaction);
  }

  async getBlockByNumber(blockNumber: number): Promise<any> {
    return await this.stateManager.getBlock(blockNumber);
  }

  async getTransactionByHash(txHash: string): Promise<any> {
    return await this.stateManager.getTransaction(txHash);
  }

  async getBalance(address: string): Promise<string> {
    return await this.stateManager.getBalance(address);
  }

  getStatus(): NodeStatus {
    return {
      isRunning: this.isRunning,
      blockHeight: this.currentBlockHeight,
      pendingTransactions: this.transactionPool?.getPendingCount() || 0,
      lastL1Sync: this.lastL1SyncBlock,
      sequencerStatus: this.sequencer?.getStatus() || 'stopped',
      validatorStatus: this.validator?.getStatus() || 'stopped'
    };
  }

  async shutdown(): Promise<void> {
    logger.info('🛑 Shutting down ZSnail L2 Node...');
    
    this.isRunning = false;
    
    if (this.sequencer) await this.sequencer.stop();
    if (this.validator) await this.validator.stop();
    if (this.bridge) await this.bridge.stop();
    
    // Close WebSocket connections
    if (this.l1WsProvider) {
      this.l1WsProvider.destroy();
    }
    
    logger.info('✅ ZSnail L2 Node shutdown complete');
  }
}