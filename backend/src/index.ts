import express from 'express';
import dotenv from 'dotenv';
import { ZSnailL2Node } from './core/ZSnailL2Node';
import { apiRoutes } from './api/routes';
import { logger } from './core/logger';

// Load environment variables
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Initialize ZSnail L2 Node
let zsnailNode: ZSnailL2Node;

async function initializeZSnailNode() {
  try {
    logger.info('🚀 Initializing ZSnail L2 Blockchain Node...');
    
    // Validate required environment variables
    if (!process.env.L1_RPC_URL || !process.env.L1_WS_URL) {
      throw new Error('Missing required environment variables: L1_RPC_URL and L1_WS_URL must be set');
    }
    
    // Initialize our custom L2 node with real configuration
    zsnailNode = new ZSnailL2Node({
      chainId: parseInt(process.env.ZSNAIL_CHAIN_ID || '66875'),
      l1RpcUrl: process.env.L1_RPC_URL!,
      l1WsUrl: process.env.L1_WS_URL!,
      rollupContractAddress: process.env.ROLLUP_CONTRACT_ADDRESS || undefined,
      bridgeContractAddress: process.env.BRIDGE_CONTRACT_ADDRESS || undefined,
    });

    await zsnailNode.initialize();
    logger.info('✅ ZSnail L2 Node initialized successfully');
  } catch (error) {
    logger.error('❌ Failed to initialize ZSnail L2 Node:', { error: String(error) });
    process.exit(1);
  }
}

// API Routes
app.use('/api/v1', apiRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    chainId: process.env.ZSNAIL_CHAIN_ID,
    network: process.env.NETWORK,
    nodeStatus: zsnailNode?.getStatus() || 'initializing'
  });
});

// Start server
async function startServer() {
  try {
    await initializeZSnailNode();
    
    app.listen(PORT, () => {
      logger.info(`🌐 ZSnail L2 Blockchain Node running on port ${PORT}`);
      logger.info(`📡 Health check: http://localhost:${PORT}/health`);
      logger.info(`🔗 API endpoint: http://localhost:${PORT}/api/v1`);
    });
  } catch (error) {
    logger.error('❌ Failed to start ZSnail L2 Node:', { error: String(error) });
    process.exit(1);
  }
}

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('🛑 Received SIGTERM, shutting down gracefully...');
  if (zsnailNode) {
    await zsnailNode.shutdown();
  }
  process.exit(0);
});

process.on('SIGINT', async () => {
  logger.info('🛑 Received SIGINT, shutting down gracefully...');
  if (zsnailNode) {
    await zsnailNode.shutdown();
  }
  process.exit(0);
});

// Start the ZSnail L2 Blockchain Node
startServer();