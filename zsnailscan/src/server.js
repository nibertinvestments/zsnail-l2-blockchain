const express = require('express');
const cors = require('cors');
const axios = require('axios');
const path = require('path');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3001;
// USE ONLY EXTERNAL KUBERNETES ENDPOINTS - NO LOCALHOST
const ZSNAIL_RPC = 'http://34.122.156.185:8545';

app.use(cors());
app.use(express.json());
app.use(express.static(path.join(__dirname, '../public')));

app.get('/', (req, res) => {
    res.sendFile(path.join(__dirname, '../public/index.html'));
});

app.get('/api/info', async (req, res) => {
    try {
        console.log(`Attempting to connect to ZSnail RPC: ${ZSNAIL_RPC}/info`);
        const response = await axios.get(`${ZSNAIL_RPC}/info`, {
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
        console.log('Successfully connected to blockchain info endpoint');
        res.json(response.data);
    } catch (error) {
        console.error('Failed to fetch blockchain info:', error.message);
        console.error('Error details:', error.response?.data || error.code);
        res.status(500).json({ 
            error: 'Failed to fetch info',
            details: error.message,
            endpoint: `${ZSNAIL_RPC}/info`
        });
    }
});

app.get('/api/wallet/:address', async (req, res) => {
    try {
        const { address } = req.params;
        console.log(`Fetching balance for address: ${address}`);
        console.log(`Using RPC endpoint: ${ZSNAIL_RPC}`);
        
        const response = await axios.post(ZSNAIL_RPC, {
            jsonrpc: '2.0',
            method: 'eth_getBalance',
            params: [address, 'latest'],
            id: 1
        }, {
            timeout: 10000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        console.log('Blockchain response received:', response.data);
        
        const balance = response.data.result;
        const balanceDecimal = parseInt(balance, 16);
        const balanceZSnail = balanceDecimal / (10**18);
        
        res.json({
            address: address,
            balanceHex: balance,
            balanceWei: balanceDecimal.toString(),
            balanceZSnail: balanceZSnail.toLocaleString(),
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Failed to fetch wallet balance:', error.message);
        console.error('Error details:', error.response?.data || error.code);
        res.status(500).json({ 
            error: 'Failed to fetch wallet',
            details: error.message,
            endpoint: ZSNAIL_RPC
        });
    }
});

// Error handling for uncaught exceptions
process.on('uncaughtException', (error) => {
    console.error('Uncaught Exception:', error);
    // Don't exit the process, just log the error
});

process.on('unhandledRejection', (reason, promise) => {
    console.error('Unhandled Rejection at:', promise, 'reason:', reason);
    // Don't exit the process, just log the error
});

// Graceful shutdown handling
process.on('SIGINT', () => {
    console.log('\nReceived SIGINT. Graceful shutdown...');
    process.exit(0);
});

process.on('SIGTERM', () => {
    console.log('\nReceived SIGTERM. Graceful shutdown...');
    process.exit(0);
});

// Health check endpoint
app.get('/health', (req, res) => {
    res.json({ 
        status: 'OK', 
        service: 'ZSnailScan',
        timestamp: new Date().toISOString(),
        blockchain_endpoint: ZSNAIL_RPC
    });
});

// Test blockchain connectivity endpoint
app.get('/api/test-connection', async (req, res) => {
    try {
        console.log(`Testing connection to: ${ZSNAIL_RPC}`);
        const response = await axios.post(ZSNAIL_RPC, {
            jsonrpc: '2.0',
            method: 'eth_blockNumber',
            params: [],
            id: 1
        }, {
            timeout: 5000,
            headers: {
                'Content-Type': 'application/json'
            }
        });
        
        const blockNumber = parseInt(response.data.result, 16);
        console.log(`Successfully connected! Current block: ${blockNumber}`);
        
        res.json({
            status: 'Connected',
            endpoint: ZSNAIL_RPC,
            currentBlock: blockNumber,
            blockHex: response.data.result,
            timestamp: new Date().toISOString()
        });
    } catch (error) {
        console.error('Connection test failed:', error.message);
        res.status(500).json({
            status: 'Failed',
            endpoint: ZSNAIL_RPC,
            error: error.message,
            timestamp: new Date().toISOString()
        });
    }
});

const server = app.listen(PORT, () => {
    console.log(`✅ ZSnailScan Server Details:`);
    console.log(`   Server: http://34.122.156.185:${PORT}`);
    console.log(`   Blockchain RPC: ${ZSNAIL_RPC}`);
    console.log(`   Health Check: http://34.122.156.185:${PORT}/health`);
    console.log(`   Connection Test: http://34.122.156.185:${PORT}/api/test-connection`);
    console.log(`   Timestamp: ${new Date().toISOString()}`);
    console.log(`\n� Testing blockchain connection...`);
    
    // Test connection on startup
    axios.post(ZSNAIL_RPC, {
        jsonrpc: '2.0',
        method: 'eth_blockNumber',
        params: [],
        id: 1
    }, {
        timeout: 5000,
        headers: { 'Content-Type': 'application/json' }
    })
    .then(response => {
        const blockNumber = parseInt(response.data.result, 16);
        console.log(`✅ Blockchain connection successful! Current block: ${blockNumber}`);
    })
    .catch(error => {
        console.error(`❌ Blockchain connection failed: ${error.message}`);
        console.error(`   Endpoint: ${ZSNAIL_RPC}`);
        console.error(`   Please check if the blockchain node is running.`);
    });
});

server.on('error', (error) => {
    if (error.code === 'EADDRINUSE') {
        console.log(`Port ${PORT} is already in use. Trying port ${PORT + 1}...`);
        server.listen(PORT + 1);
    } else {
        console.error('Server error:', error);
    }
});
