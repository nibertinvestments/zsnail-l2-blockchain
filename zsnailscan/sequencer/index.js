const express = require('express');
const cors = require('cors');
const crypto = require('crypto');

class ZSnailSequencer {
  constructor() {
    this.app = express();
    this.chainId = this.generateChainId();
    this.blockNumber = 0;
    this.blocks = [];
    this.pendingTransactions = [];
    
    // Proof of Work configuration
    this.difficulty = 2; // Number of leading zeros required (start easy)
    this.blockReward = '50000000000000000000'; // 50 ZSNAIL reward per block (native token)
    this.isMining = false;
    this.minerAddress = '0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48'; // Your wallet as default miner
    
    // Native ZSNAIL Token Integration (Like ETH on Ethereum)
    this.zsnailTokenAddress = null; // Will be set when deployed
    this.gasTokenEnabled = true;
    this.zsnailGasRate = 12500; // 1 ETH = 12,500 ZSNAIL rate from hybrid model
    this.zsnailNativeBalances = new Map(); // Track native ZSNAIL balances
    this.zsnailBalances = new Map(); // Legacy compatibility
    
    // Native ZSNAIL Mining Configuration
    this.currentBlockReward = BigInt('50000000000000000000'); // 50 ZSNAIL per block
    this.maxSupply = BigInt('210000000000000000000000000000'); // 210 billion ZSNAIL max
    this.totalSupply = BigInt('100000000000000000000000000'); // Initial 100 million ZSNAIL
    this.halvingInterval = 525600; // Halving every 525,600 blocks (~3 years)
    this.lastHalvingBlock = 0;
    
    // Reward distribution percentages (Bitcoin-like)
    this.minerRewardPercentage = 70; // 70% to miners
    this.validatorRewardPercentage = 20; // 20% to validators  
    this.treasuryRewardPercentage = 10; // 10% to treasury
    
    // Initialize your wallet with native ZSNAIL balance
    this.zsnailNativeBalances.set('0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48', BigInt('1000000000000000000000')); // 1000 ZSNAIL initial
    
    // Validator Network
    this.validators = new Map();
    this.validatorNodes = [];
    this.consensusThreshold = 67; // 67% agreement
    this.validationRewards = new Map();
    
    // Wallet and balance tracking
    this.wallets = new Map();
    this.balances = new Map();
    this.nonces = new Map();
    
    // Initialize your wallet
    this.initializeWallet('0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48');
    
    // Initialize genesis block
    this.createGenesisBlock();
    
    // Setup middleware
    this.app.use(cors());
    this.app.use(express.json());
    
    // Setup routes
    this.setupRoutes();
    
    // Start Proof of Work mining
    this.startPoWMining();
  }
  
  generateChainId() {
    // ZSnail L2 Permanent Chain ID - NEVER CHANGES
    // This is your official blockchain identity
    const chainId = 66875;
    
    console.log(`🎯 ZSnail L2 Chain ID: ${chainId} (PERMANENT)`);
    return chainId;
  }
  
  initializeWallet(address) {
    this.balances.set(address, '0'); // Start with 0 balance
    this.nonces.set(address, 0);
    this.wallets.set(address, {
      address: address,
      connected: true,
      type: 'miner'
    });
    console.log(`👛 Wallet initialized: ${address}`);
  }
  
  getBalance(address) {
    return this.balances.get(address) || '0';
  }
  
  // Native ZSNAIL Mining Functions
  startPoWMining() {
    console.log('🚀 Starting Proof of Work mining with native ZSNAIL rewards...');
    this.isMining = true;
    
    const mineNewBlock = () => {
      if (!this.isMining) {return;}
      
      const blockNumber = this.blockNumber + 1;
      const parentHash = this.blocks[this.blockNumber]?.hash || '0x0000000000000000000000000000000000000000000000000000000000000000';
      const transactions = [...this.pendingTransactions];
      
      console.log(`\n⛏️  Mining block ${blockNumber} with ${transactions.length} transactions...`);
      
      // Mine the block
      const { hash, nonce, attempts, miningTime } = this.mineBlock(blockNumber, parentHash, transactions);
      
      // Create the new block with ZSNAIL mining rewards
      const newBlock = {
        number: blockNumber,
        hash: hash,
        parentHash: parentHash,
        transactions: transactions,
        timestamp: Date.now(),
        difficulty: this.difficulty,
        nonce: nonce,
        gasLimit: '0x1c9c380',
        gasUsed: '0x0',
        miner: this.minerAddress,
        attempts: attempts,
        miningTime: miningTime,
        zsnailReward: this.currentBlockReward.toString(),
        totalSupply: this.totalSupply.toString()
      };
      
      this.blocks[blockNumber] = newBlock;
      this.blockNumber = blockNumber;
      
      // Clear pending transactions
      this.pendingTransactions = [];
      
      // Distribute ZSNAIL mining rewards
      this.distributeZSnailMiningRewards(blockNumber);
      
      // Check for halving
      this.checkForHalving(blockNumber);
      
      console.log(`✅ Block ${blockNumber} added to blockchain with ZSNAIL rewards!`);
      console.log(`🐌 Your ZSNAIL balance: ${this.formatZSnailBalance(this.getZSnailBalance(this.minerAddress))} ZSNAIL`);
      
      // Continue mining
      setTimeout(mineNewBlock, 2000); // Mine every 2 seconds
    };
    
    // Start mining
    setTimeout(mineNewBlock, 1000); // Start after 1 second
  }
  
  // Distribute ZSNAIL mining rewards (simplified for single miner setup)
  distributeZSnailMiningRewards(blockNumber) {
    const currentReward = this.getCurrentBlockReward();
    
    // For now, since we have no active validators, miner gets all rewards
    const activeValidators = Array.from(this.validators.values()).filter(v => v.isActive);
    
    if (activeValidators.length === 0) {
      // No validators yet - miner gets 100% of rewards
      console.log('⚠️  No active validators - miner receives full block reward');
      
      const currentMinerBalance = BigInt(this.getZSnailBalance(this.minerAddress));
      const newMinerBalance = currentMinerBalance + currentReward;
      this.zsnailNativeBalances.set(this.minerAddress, newMinerBalance);
      
      console.log(`💰 Mining Reward (Block ${blockNumber}):`);
      console.log(`   🔨 Miner (100%): ${this.formatZSnailBalance(currentReward)} ZSNAIL`);
      console.log(`   📊 Your Balance: ${this.formatZSnailBalance(newMinerBalance)} ZSNAIL`);
    } else {
      // Normal distribution with active validators
      const minerReward = (currentReward * BigInt(this.minerRewardPercentage)) / BigInt(100);
      const validatorReward = (currentReward * BigInt(this.validatorRewardPercentage)) / BigInt(100);
      const treasuryReward = (currentReward * BigInt(this.treasuryRewardPercentage)) / BigInt(100);
      
      // Pay miner (your wallet)
      const currentMinerBalance = BigInt(this.getZSnailBalance(this.minerAddress));
      const newMinerBalance = currentMinerBalance + minerReward;
      this.zsnailNativeBalances.set(this.minerAddress, newMinerBalance);
      
      // Pay validators (distributed among active validators)
      const rewardPerValidator = validatorReward / BigInt(activeValidators.length);
      for (const validator of activeValidators) {
        const currentBalance = BigInt(this.getZSnailBalance(validator.address));
        const newBalance = currentBalance + rewardPerValidator;
        this.zsnailNativeBalances.set(validator.address, newBalance);
      }
      
      // Pay treasury
      const treasuryAddress = '0x742d35Cc6634C0532925a3b8c7C025B0e4FfFf9C';
      const currentTreasuryBalance = BigInt(this.getZSnailBalance(treasuryAddress));
      const newTreasuryBalance = currentTreasuryBalance + treasuryReward;
      this.zsnailNativeBalances.set(treasuryAddress, newTreasuryBalance);
      
      console.log(`💰 ZSNAIL Rewards Distributed (Block ${blockNumber}):`);
      console.log(`   🔨 Miner (70%): ${this.formatZSnailBalance(minerReward)} ZSNAIL`);
      console.log(`   ⚡ Validators (20%): ${this.formatZSnailBalance(validatorReward)} ZSNAIL`);
      console.log(`   🏦 Treasury (10%): ${this.formatZSnailBalance(treasuryReward)} ZSNAIL`);
    }
    
    // Update total supply
    this.totalSupply = this.totalSupply + currentReward;
    console.log(`   📊 Total Supply: ${this.formatZSnailBalance(this.totalSupply)} ZSNAIL`);
  }
  
  // Get current block reward (with halving)
  getCurrentBlockReward() {
    const halvingCount = Math.floor((this.blockNumber - this.lastHalvingBlock) / this.halvingInterval);
    return this.currentBlockReward / (BigInt(2) ** BigInt(halvingCount));
  }
  
  // Check for halving (like Bitcoin)
  checkForHalving(blockNumber) {
    if (blockNumber > 0 && blockNumber % this.halvingInterval === 0) {
      this.currentBlockReward = this.currentBlockReward / BigInt(2);
      this.lastHalvingBlock = blockNumber;
      
      console.log(`🔥 ZSNAIL HALVING EVENT! Block ${blockNumber}`);
      console.log(`   New block reward: ${this.formatZSnailBalance(this.currentBlockReward)} ZSNAIL`);
    }
  }
  
  // Get ZSNAIL balance for address
  getZSnailBalance(address) {
    return this.zsnailNativeBalances.get(address) || BigInt(0);
  }
  
  // Format ZSNAIL balance for display
  formatZSnailBalance(balance) {
    const balanceBig = typeof balance === 'bigint' ? balance : BigInt(balance);
    const balanceEth = Number(balanceBig) / 1e18;
    return balanceEth.toLocaleString(undefined, { maximumFractionDigits: 6 });
  }
  
  // Check if address can pay gas in ZSNAIL
  canPayGasInZSnail(address, gasAmount) {
    const balance = this.getZSnailBalance(address);
    const gasRequired = BigInt(gasAmount) * BigInt(this.zsnailGasRate);
    return balance >= gasRequired;
  }
  
  // Deduct ZSNAIL for gas payment
  payGasInZSnail(address, gasAmount) {
    const balance = this.getZSnailBalance(address);
    const gasCost = BigInt(gasAmount) * BigInt(this.zsnailGasRate);
    
    if (balance >= gasCost) {
      const newBalance = balance - gasCost;
      this.zsnailNativeBalances.set(address, newBalance);
      return true;
    }
    return false;
  }

  addReward() {
    // Legacy function - now handled by ZSNAIL mining rewards
    console.log('Legacy reward function called, using ZSNAIL mining instead');
  }
  
  createGenesisBlock() {
    const genesisBlock = {
      number: 0,
      hash: this.generateBlockHash(0, '0x0', [], 0),
      parentHash: '0x0',
      timestamp: Math.floor(Date.now() / 1000),
      transactions: [],
      gasUsed: 0,
      gasLimit: 30000000,
      difficulty: this.difficulty,
      nonce: 0,
      miner: '0x0000000000000000000000000000000000000000'
    };
    
    this.blocks.push(genesisBlock);
    console.log(`🏗️  Genesis block created: ${genesisBlock.hash}`);
  }
  
  generateBlockHash(blockNumber, parentHash, transactions, nonce) {
    const data = `${blockNumber}${parentHash}${JSON.stringify(transactions)}${nonce}`;
    return '0x' + crypto.createHash('sha256').update(data).digest('hex');
  }
  
  // Proof of Work mining function
  mineBlock(blockNumber, parentHash, transactions) {
    const target = '0'.repeat(this.difficulty);
    let nonce = 0;
    let hash;
    let attempts = 0;
    
    const startTime = Date.now();
    
    do {
      nonce++;
      attempts++;
      hash = this.generateBlockHash(blockNumber, parentHash, transactions, nonce);
      
      // Progress indicator every 10000 attempts
      if (attempts % 10000 === 0) {
        process.stdout.write(`⛏️  Mining... ${attempts} attempts, nonce: ${nonce}\r`);
      }
      
    } while (!hash.substring(2, 2 + this.difficulty).startsWith(target));
    
    const miningTime = (Date.now() - startTime) / 1000;
    console.log(`\n⛏️  Block mined! Hash: ${hash.substring(0, 12)}... | Nonce: ${nonce} | Time: ${miningTime}s | Attempts: ${attempts}`);
    
    return { hash, nonce, attempts, miningTime };
  }
  
  setupRoutes() {
    // Ethereum JSON-RPC compatibility
    this.app.post('/', (req, res) => {
      const { method, params, id } = req.body;
      
      try {
        let result;
        
        switch (method) {
        case 'eth_chainId':
          result = `0x${this.chainId.toString(16)}`;
          break;
            
        case 'eth_blockNumber':
          result = `0x${this.blockNumber.toString(16)}`;
          break;
            
        case 'eth_getBlockByNumber': {
          const blockNum = params[0] === 'latest' ? this.blockNumber : parseInt(params[0], 16);
          const block = this.blocks[blockNum];
          result = block || null;
          break;
        }
            
        case 'eth_gasPrice':
          result = '0x3b9aca00'; // 1 gwei
          break;
            
        case 'net_version':
          result = this.chainId.toString();
          break;
            
          // Wallet-related methods
        case 'eth_getBalance': {
          const address = params[0];
          // Return ZSNAIL balance as the native balance
          const zsnailBalance = this.getZSnailBalance(address);
          result = `0x${zsnailBalance.toString(16)}`;
          break;
        }
            
        case 'eth_getTransactionCount': {
          const addr = params[0];
          const nonce = this.nonces.get(addr) || 0;
          result = `0x${nonce.toString(16)}`;
          break;
        }
            
        case 'eth_accounts':
          result = Array.from(this.wallets.keys());
          break;
            
        case 'eth_coinbase':
          result = this.minerAddress;
          break;
            
          // Additional MetaMask-compatible methods
        case 'eth_sendTransaction':
          // Basic transaction support (simplified)
          result = '0x' + crypto.createHash('sha256').update(JSON.stringify(params[0])).digest('hex');
          break;
            
        case 'eth_estimateGas':
          result = '0x5208'; // 21000 gas (standard transfer)
          break;
            
        case 'eth_feeHistory':
          // EIP1559 fee history for compatibility
          result = {
            oldestBlock: '0x1',
            baseFeePerGas: ['0x3b9aca00'], // 1 gwei
            gasUsedRatio: [0.5],
            reward: [['0x3b9aca00']] // 1 gwei priority fee
          };
          break;
            
        case 'eth_call':
          // Basic call support
          result = '0x';
          break;
            
        case 'web3_clientVersion':
          result = 'ZSnail-L2/v1.0.0';
          break;
            
        case 'net_listening':
          result = true;
          break;
            
        case 'net_peerCount':
          result = '0x1';
          break;
            
        case 'eth_protocolVersion':
          result = '0x41'; // 65
          break;
            
        case 'eth_syncing':
          result = false;
          break;
            
        case 'eth_mining':
          result = this.isMining;
          break;
            
        case 'eth_hashrate':
          result = '0x100000'; // Mock hashrate
          break;
            
        default:
          throw new Error(`Method ${method} not supported`);
        }
        
        res.json({ jsonrpc: '2.0', id, result });
      } catch (error) {
        res.json({
          jsonrpc: '2.0',
          id,
          error: { code: -32603, message: error.message }
        });
      }
    });
    
    // Health check endpoint
    this.app.get('/health', (req, res) => {
      res.json({
        status: 'healthy',
        chainId: this.chainId,
        blockNumber: this.blockNumber,
        totalBlocks: this.blocks.length,
        pendingTransactions: this.pendingTransactions.length,
        timestamp: Date.now()
      });
    });
    
    // Chain info endpoint
    this.app.get('/info', (req, res) => {
      res.json({
        name: 'ZSnail L2',
        chainId: this.chainId,
        chainIdHex: `0x${this.chainId.toString(16)}`,
        blockNumber: this.blockNumber,
        consensusType: 'Proof of Work',
        difficulty: this.difficulty,
        blockReward: this.formatZSnailBalance(this.currentBlockReward) + ' ZSNAIL',
        minerAddress: this.minerAddress,
        minerBalance: this.getZSnailBalance(this.minerAddress).toString(),
        minerBalanceZSnail: this.formatZSnailBalance(this.getZSnailBalance(this.minerAddress)),
        isMining: this.isMining,
        gasPrice: '1000000000',
        totalBlocks: this.blocks.length,
        connectedWallets: this.wallets.size,
        totalSupplyZSnail: this.formatZSnailBalance(this.totalSupply),
        status: 'running'
      });
    });
    
    // Wallet endpoints
    this.app.get('/wallet/:address', (req, res) => {
      const address = req.params.address;
      const wallet = this.wallets.get(address);
      
      if (wallet) {
        res.json({
          address: address,
          balance: this.getZSnailBalance(address).toString(),
          balanceZSnail: this.formatZSnailBalance(this.getZSnailBalance(address)),
          nonce: this.nonces.get(address) || 0,
          connected: wallet.connected,
          type: wallet.type,
          isMiner: address === this.minerAddress,
          canPayGas: this.canPayGasInZSnail(address, 21000)
        });
      } else {
        res.status(404).json({ error: 'Wallet not found' });
      }
    });
    
    this.app.post('/wallet/connect', (req, res) => {
      const { address } = req.body;
      
      if (address) {
        this.initializeWallet(address);
        res.json({
          success: true,
          message: `Wallet ${address} connected successfully`,
          balance: this.getZSnailBalance(address).toString(),
          balanceZSnail: this.formatZSnailBalance(this.getZSnailBalance(address)),
          chainId: this.chainId
        });
      } else {
        res.json({ success: false, message: 'Address required' });
      }
    });
    
    this.app.get('/wallets', (req, res) => {
      const walletList = Array.from(this.wallets.entries()).map(([address, wallet]) => ({
        address: address,
        balance: this.getZSnailBalance(address).toString(),
        balanceZSnail: this.formatZSnailBalance(this.getZSnailBalance(address)),
        nonce: this.nonces.get(address) || 0,
        isMiner: address === this.minerAddress,
        type: wallet.type || 'user'
      }));
      
      res.json({
        totalWallets: walletList.length,
        wallets: walletList,
        chainId: this.chainId
      });
    });
    
    // BLOCKCHAIN EXPLORER ENDPOINTS
    this.app.get('/explorer', (req, res) => {
      const totalFees = this.calculateTotalFees();
      const totalTransactions = this.calculateTotalTransactions();
      
      res.json({
        chainId: this.chainId,
        networkName: 'ZSnail L2',
        consensus: 'Proof of Work',
        totalBlocks: this.blocks.length,
        totalTransactions: totalTransactions,
        difficulty: this.difficulty,
        hashrate: this.calculateHashrate(),
        totalFees: totalFees,
        totalFeesETH: totalFees / 1e18,
        minerBalance: this.getBalance(this.minerAddress),
        minerBalanceETH: (BigInt(this.getBalance(this.minerAddress)) / BigInt(1e18)).toString(),
        blockReward: this.blockReward,
        blockRewardETH: parseInt(this.blockReward) / 1e18,
        recentBlocks: this.blocks.slice(-10).map(block => ({
          number: block.number,
          hash: block.hash.substring(0, 16) + '...',
          timestamp: block.timestamp,
          transactions: block.transactions?.length || 0,
          miner: block.miner,
          reward: block.reward || this.blockReward,
          difficulty: block.difficulty,
          nonce: block.nonce,
          miningTime: block.miningTime || 0,
          attempts: block.attempts || 0
        }))
      });
    });
    
    this.app.get('/explorer/block/:number', (req, res) => {
      const blockNumber = parseInt(req.params.number);
      if (blockNumber < 0 || blockNumber >= this.blocks.length) {
        return res.status(404).json({ error: 'Block not found' });
      }
      
      const block = this.blocks[blockNumber];
      res.json({
        ...block,
        size: JSON.stringify(block).length,
        age: Date.now() - (block.timestamp * 1000),
        confirmations: this.blocks.length - blockNumber,
        rewardETH: parseInt(block.reward || this.blockReward) / 1e18,
        miningTimeSeconds: (block.miningTime || 0) / 1000
      });
    });
    
    this.app.get('/explorer/fees', (req, res) => {
      const totalFees = this.calculateTotalFees();
      const transactionCount = this.calculateTotalTransactions();
      
      res.json({
        totalFees: totalFees,
        totalFeesETH: totalFees / 1e18,
        totalTransactions: transactionCount,
        averageFee: transactionCount > 0 ? totalFees / transactionCount : 0,
        averageFeeETH: transactionCount > 0 ? (totalFees / transactionCount) / 1e18 : 0,
        feesPerBlock: this.blocks.length > 0 ? totalFees / this.blocks.length : 0
      });
    });
    
    this.app.get('/explorer/stats', (req, res) => {
      const totalFees = this.calculateTotalFees();
      const hashrate = this.calculateHashrate();
      
      res.json({
        chainStats: {
          chainId: this.chainId,
          totalBlocks: this.blocks.length,
          totalTransactions: this.calculateTotalTransactions(),
          totalWallets: this.wallets.size,
          totalSupply: Array.from(this.wallets.keys()).reduce((sum, addr) => sum + BigInt(this.getBalance(addr)), BigInt(0)).toString(),
          totalSupplyETH: (Array.from(this.wallets.keys()).reduce((sum, addr) => sum + BigInt(this.getBalance(addr)), BigInt(0)) / BigInt(1e18)).toString()
        },
        miningStats: {
          difficulty: this.difficulty,
          hashrate: hashrate,
          blockReward: this.blockReward,
          blockRewardETH: parseInt(this.blockReward) / 1e18,
          isMining: this.isMining,
          minerAddress: this.minerAddress
        },
        feeStats: {
          totalFees: totalFees,
          totalFeesETH: totalFees / 1e18,
          averageBlockTime: this.calculateAverageBlockTime()
        }
      });
    });
    
    // MetaMask integration page
    this.app.get('/metamask', (req, res) => {
      const fs = require('fs');
      const path = require('path');
      
      try {
        const htmlPath = path.join(__dirname, 'metamask', 'add-zsnail-to-metamask.html');
        const html = fs.readFileSync(htmlPath, 'utf8');
        res.send(html);
      } catch (error) {
        res.status(404).send(`
          <h1>MetaMask Integration</h1>
          <p>MetaMask integration file not found. Please check the file exists at: ../metamask/add-zsnail-to-metamask.html</p>
          <p>Network Details:</p>
          <ul>
            <li><strong>Network Name:</strong> ZSnail L2 Proof of Work</li>
            <li><strong>RPC URL:</strong> http://localhost:8545</li>
            <li><strong>Chain ID:</strong> 66875</li>
            <li><strong>Currency Symbol:</strong> ETH</li>
          </ul>
        `);
      }
    });
    
    // Mining control endpoints
    this.app.post('/mining/start', (req, res) => {
      if (!this.isMining) {
        this.mineNextBlock();
        res.json({ success: true, message: 'Mining started' });
      } else {
        res.json({ success: false, message: 'Already mining' });
      }
    });
    
    this.app.post('/mining/stop', (req, res) => {
      this.isMining = false;
      res.json({ success: true, message: 'Mining stopped' });
    });
    
    this.app.post('/mining/setMiner', (req, res) => {
      const { address } = req.body;
      if (address) {
        this.minerAddress = address;
        res.json({ success: true, message: `Miner address set to ${address}` });
      } else {
        res.json({ success: false, message: 'Address required' });
      }
    });
    
    this.app.post('/mining/setDifficulty', (req, res) => {
      const { difficulty } = req.body;
      if (difficulty && difficulty > 0) {
        this.difficulty = parseInt(difficulty);
        res.json({ success: true, message: `Difficulty set to ${this.difficulty}` });
      } else {
        res.json({ success: false, message: 'Valid difficulty required' });
      }
    });
    
    // ZSNAIL TOKEN & GAS ENDPOINTS
    this.app.post('/gas/payWithZSnail', (req, res) => {
      const { address, gasUsed } = req.body;
      
      try {
        const gasResult = this.payGasWithZSnail(address, gasUsed);
        res.json({ 
          success: true, 
          zsnailUsed: gasResult.zsnailAmount,
          ethEquivalent: gasResult.ethEquivalent,
          newBalance: this.getZSnailBalance(address)
        });
      } catch (error) {
        res.json({ success: false, message: error.message });
      }
    });
    
    this.app.get('/gas/rate', (req, res) => {
      res.json({
        zsnailPerEth: this.zsnailGasRate,
        gasTokenEnabled: this.gasTokenEnabled,
        currentGasPrice: '1000000000', // 1 gwei
        zsnailTokenAddress: this.zsnailTokenAddress
      });
    });
    
    this.app.post('/gas/setRate', (req, res) => {
      const { rate } = req.body;
      if (rate && rate > 0) {
        this.zsnailGasRate = parseInt(rate);
        res.json({ success: true, message: `ZSnail gas rate set to ${rate}` });
      } else {
        res.json({ success: false, message: 'Valid rate required' });
      }
    });
    
    this.app.get('/zsnail/balance/:address', (req, res) => {
      const address = req.params.address;
      const balance = this.getZSnailBalance(address);
      res.json({
        address: address,
        zsnailBalance: balance,
        zsnailBalanceFormatted: (parseInt(balance) / 1e18).toString(),
        canPayGas: parseInt(balance) > 0
      });
    });
    
    // VALIDATOR NETWORK ENDPOINTS
    this.app.post('/validator/register', (req, res) => {
      const { address, nodeUrl, region, stake } = req.body;
      
      try {
        const result = this.registerValidator(address, nodeUrl, region, stake);
        res.json({ success: true, validatorId: result.id, message: 'Validator registered successfully' });
      } catch (error) {
        res.json({ success: false, message: error.message });
      }
    });
    
    this.app.post('/validator/submitValidation', (req, res) => {
      const { validatorAddress, blockNumber, blockHash, isValid } = req.body;
      
      try {
        const result = this.submitValidation(validatorAddress, blockNumber, blockHash, isValid);
        res.json({ 
          success: true, 
          validationId: result.id,
          consensusReached: result.consensus,
          reward: result.reward
        });
      } catch (error) {
        res.json({ success: false, message: error.message });
      }
    });
    
    this.app.get('/validator/list', (req, res) => {
      const validators = Array.from(this.validators.values()).map(v => ({
        address: v.address,
        nodeUrl: v.nodeUrl,
        region: v.region,
        stake: v.stake,
        reputation: v.reputation,
        isActive: v.isActive,
        blocksValidated: v.blocksValidated,
        joinedAt: v.joinedAt
      }));
      
      res.json({
        totalValidators: validators.length,
        activeValidators: validators.filter(v => v.isActive).length,
        consensusThreshold: this.consensusThreshold,
        validators: validators
      });
    });
    
    this.app.get('/validator/consensus/:blockNumber', (req, res) => {
      const blockNumber = parseInt(req.params.blockNumber);
      const consensus = this.getBlockConsensus(blockNumber);
      
      res.json({
        blockNumber: blockNumber,
        totalValidations: consensus.total,
        validCount: consensus.valid,
        invalidCount: consensus.invalid,
        consensusReached: consensus.reached,
        consensusResult: consensus.result,
        validators: consensus.validators
      });
    });
    
    this.app.get('/validator/rewards/:address', (req, res) => {
      const address = req.params.address;
      const rewards = this.getValidatorRewards(address);
      
      res.json({
        validatorAddress: address,
        totalRewards: rewards.total,
        rewardsThisWeek: rewards.thisWeek,
        validationsCompleted: rewards.validations,
        reputation: rewards.reputation,
        nextRewardEstimate: rewards.nextEstimate
      });
    });
    
    // TOKENOMICS AND REWARDS ENDPOINTS
    this.app.get('/tokenomics/overview', (req, res) => {
      res.json({
        zsnailToken: {
          totalSupply: this.getTotalZSnailSupply(),
          circulatingSupply: this.getCirculatingZSnailSupply(),
          gasTokenEnabled: this.gasTokenEnabled,
          gasRate: this.zsnailGasRate
        },
        mining: {
          currentReward: this.blockReward,
          totalMined: this.getTotalMinedRewards(),
          difficulty: this.difficulty,
          avgBlockTime: this.calculateAverageBlockTime()
        },
        validation: {
          totalValidators: this.validators.size,
          activeValidators: Array.from(this.validators.values()).filter(v => v.isActive).length,
          totalStaked: this.getTotalValidatorStake(),
          validationRewardRate: this.getValidationRewardRate()
        }
      });
    });
  }
  
  // Helper functions for blockchain explorer
  calculateTotalFees() {
    let totalFees = 0;
    this.blocks.forEach(block => {
      if (block.transactions) {
        block.transactions.forEach(tx => {
          totalFees += (tx.gasUsed || 21000) * (tx.gasPrice || 1000000000);
        });
      }
    });
    return totalFees;
  }
  
  calculateTotalTransactions() {
    return this.blocks.reduce((sum, block) => sum + (block.transactions?.length || 0), 0);
  }
  
  calculateHashrate() {
    if (this.blocks.length < 2) {return 0;}
    
    const recentBlocks = this.blocks.slice(-10);
    let totalAttempts = 0;
    let totalTime = 0;
    
    recentBlocks.forEach(block => {
      if (block.attempts && block.miningTime) {
        totalAttempts += block.attempts;
        totalTime += block.miningTime / 1000; // Convert to seconds
      }
    });
    
    return totalTime > 0 ? Math.round(totalAttempts / totalTime) : 0;
  }
  
  calculateAverageBlockTime() {
    if (this.blocks.length < 2) {return 0;}
    
    const recentBlocks = this.blocks.slice(-10);
    let totalTime = 0;
    
    for (let i = 1; i < recentBlocks.length; i++) {
      totalTime += recentBlocks[i].timestamp - recentBlocks[i-1].timestamp;
    }
    
    return recentBlocks.length > 1 ? totalTime / (recentBlocks.length - 1) : 0;
  }

  // Non-blocking mining function
  async mineBlockAsync(blockNumber, parentHash, transactions) {
    const self = this; // Store reference to this for use in Promise
    return new Promise((resolve) => {
      const startTime = Date.now();
      let nonce = 0;
      let attempts = 0;
      
      const mine = () => {
        const batchSize = 1000; // Process in batches to avoid blocking
        let batchAttempts = 0;
        
        while (batchAttempts < batchSize) {
          const hash = self.generateBlockHash(blockNumber, parentHash, transactions, nonce);
          attempts++;
          batchAttempts++;
          
          if (hash.startsWith('0'.repeat(self.difficulty))) {
            const miningTime = Date.now() - startTime;
            console.log(`⛏️  Block mined! Hash: ${hash.substring(0, 16)}... | Nonce: ${nonce} | Time: ${miningTime/1000}s | Attempts: ${attempts}`);
            resolve({ hash, nonce, attempts, miningTime });
            return;
          }
          
          nonce++;
        }
        
        // Log progress every 10,000 attempts
        if (attempts % 10000 === 0) {
          console.log(`⛏️  Mining... ${attempts} attempts, nonce: ${nonce}`);
        }
        
        // Use setImmediate to yield control back to event loop
        setImmediate(mine);
      };
      
      mine();
    });
  }

  adjustDifficulty(lastMiningTime) {
    const targetTime = 5; // Target 5 seconds per block
    
    if (lastMiningTime < targetTime * 0.5) {
      // Too fast, increase difficulty
      this.difficulty++;
      console.log(`📈 Difficulty increased to ${this.difficulty} (blocks too fast)`);
    } else if (lastMiningTime > targetTime * 2) {
      // Too slow, decrease difficulty
      this.difficulty = Math.max(1, this.difficulty - 1);
      console.log(`📉 Difficulty decreased to ${this.difficulty} (blocks too slow)`);
    }
  }
  
  start(port = 8545) {
    this.app.listen(port, '0.0.0.0', () => {
      console.log(`\n🌐 ZSnail L2 Proof of Work Blockchain running on port ${port}`);
      console.log(`🔗 Chain ID: ${this.chainId} (PERMANENT)`);
      console.log('⛏️  Consensus: Proof of Work');
      console.log(`💎 Difficulty: ${this.difficulty}`);
      console.log(`💰 Block Reward: ${parseInt(this.blockReward) / 1e18} ETH`);
      console.log(`� Connected Wallet: ${this.minerAddress}`);
      console.log(`💵 Wallet Balance: ${(BigInt(this.getBalance(this.minerAddress)) / BigInt(1e18)).toString()} ETH`);
      console.log(`�📡 RPC Endpoint: http://localhost:${port}`);
      console.log(`❤️  Health Check: http://localhost:${port}/health`);
      console.log(`ℹ️  Chain Info: http://localhost:${port}/info`);
      console.log(`👛 Wallet Info: http://localhost:${port}/wallet/${this.minerAddress}`);
      console.log(`📋 All Wallets: http://localhost:${port}/wallets`);
      console.log('⛏️  Mining Controls:');
      console.log('   POST /mining/start - Start mining');
      console.log('   POST /mining/stop - Stop mining');
      console.log('   POST /mining/setMiner - Set miner address');
      console.log('   POST /mining/setDifficulty - Set difficulty');
      console.log('👛 Wallet Controls:');
      console.log('   POST /wallet/connect - Connect new wallet');
      console.log('   GET /wallet/:address - Get wallet info');
      console.log('\n✅ Your ZSnail L2 Proof of Work blockchain is now live!');
    });
  }
  
  // ========================================
  // ZSNAIL TOKEN & GAS FUNCTIONALITY
  // ========================================
  
  /**
   * Pay gas fees using ZSnail tokens
   */
  payGasWithZSnail(address, gasUsed) {
    if (!this.gasTokenEnabled) {
      throw new Error('Gas token payments disabled');
    }
    
    const gasPrice = 1000000000; // 1 gwei
    const ethRequired = gasUsed * gasPrice;
    const zsnailRequired = Math.floor(ethRequired * this.zsnailGasRate / 1e18);
    
    const zsnailBalance = this.getZSnailBalance(address);
    if (parseInt(zsnailBalance) < zsnailRequired) {
      throw new Error('Insufficient ZSnail balance for gas');
    }
    
    // Deduct ZSnail tokens
    this.setZSnailBalance(address, (parseInt(zsnailBalance) - zsnailRequired).toString());
    
    // Add to gas fee pool
    this.addToGasFeePool(zsnailRequired);
    
    return {
      zsnailAmount: zsnailRequired,
      ethEquivalent: ethRequired / 1e18
    };
  }
  
  /**
   * Set ZSnail token balance
   */
  setZSnailBalance(address, balance) {
    // Convert to BigInt for native ZSNAIL handling
    const balanceBig = typeof balance === 'string' ? BigInt(balance) : BigInt(balance.toString());
    this.zsnailNativeBalances.set(address, balanceBig);
  }
  
  /**
   * Initialize ZSnail balance for testing
   */
  initializeZSnailBalance(address, amount) {
    this.setZSnailBalance(address, amount);
  }
  
  /**
   * Add to gas fee collection pool
   */
  addToGasFeePool(amount) {
    const currentPool = this.getZSnailBalance('GAS_FEE_POOL');
    this.setZSnailBalance('GAS_FEE_POOL', (parseInt(currentPool) + amount).toString());
  }
  
  // ========================================
  // VALIDATOR NETWORK FUNCTIONALITY
  // ========================================
  
  /**
   * Register a new validator
   */
  registerValidator(address, nodeUrl, region, stake) {
    if (this.validators.has(address)) {
      throw new Error('Validator already registered');
    }
    
    const minStake = 10000; // 10K ZSNAIL minimum
    if (parseInt(stake) < minStake) {
      throw new Error(`Minimum stake of ${minStake} ZSNAIL required`);
    }
    
    const validator = {
      id: `val_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      address: address,
      nodeUrl: nodeUrl,
      region: region,
      stake: stake,
      reputation: 100,
      isActive: true,
      blocksValidated: 0,
      joinedAt: Date.now(),
      lastActivity: Date.now()
    };
    
    this.validators.set(address, validator);
    this.validatorNodes.push(address);
    
    // Stake ZSnail tokens
    const currentBalance = this.getZSnailBalance(address);
    if (parseInt(currentBalance) < parseInt(stake)) {
      throw new Error('Insufficient ZSnail balance for staking');
    }
    
    this.setZSnailBalance(address, (parseInt(currentBalance) - parseInt(stake)).toString());
    
    return { id: validator.id };
  }
  
  /**
   * Submit block validation
   */
  submitValidation(validatorAddress, blockNumber, blockHash, isValid) {
    const validator = this.validators.get(validatorAddress);
    if (!validator || !validator.isActive) {
      throw new Error('Invalid or inactive validator');
    }
    
    const validationId = `validation_${blockNumber}_${validatorAddress}_${Date.now()}`;
    
    // Store validation result
    if (!this.blockValidations) {
      this.blockValidations = new Map();
    }
    
    if (!this.blockValidations.has(blockNumber)) {
      this.blockValidations.set(blockNumber, []);
    }
    
    const validations = this.blockValidations.get(blockNumber);
    
    // Check if already validated
    const existingValidation = validations.find(v => v.validator === validatorAddress);
    if (existingValidation) {
      throw new Error('Block already validated by this validator');
    }
    
    // Add validation
    validations.push({
      id: validationId,
      validator: validatorAddress,
      blockNumber: blockNumber,
      blockHash: blockHash,
      isValid: isValid,
      timestamp: Date.now()
    });
    
    // Update validator stats
    validator.blocksValidated++;
    validator.lastActivity = Date.now();
    
    // Check for consensus
    const consensus = this.checkConsensus(blockNumber);
    
    // Reward validator
    const reward = this.rewardValidator(validatorAddress, consensus.reached);
    
    return {
      id: validationId,
      consensus: consensus.reached,
      reward: reward
    };
  }
  
  /**
   * Check if consensus is reached for a block
   */
  checkConsensus(blockNumber) {
    const validations = this.blockValidations.get(blockNumber) || [];
    const totalValidations = validations.length;
    const validCount = validations.filter(v => v.isValid).length;
    const invalidCount = totalValidations - validCount;
    
    const activeValidators = Array.from(this.validators.values()).filter(v => v.isActive).length;
    const minValidationsNeeded = Math.ceil(activeValidators * this.consensusThreshold / 100);
    
    const consensusReached = totalValidations >= minValidationsNeeded;
    const consensusResult = validCount > invalidCount ? 'valid' : 'invalid';
    
    return {
      total: totalValidations,
      valid: validCount,
      invalid: invalidCount,
      reached: consensusReached,
      result: consensusResult,
      validators: validations.map(v => ({
        validator: v.validator,
        result: v.isValid,
        timestamp: v.timestamp
      }))
    };
  }
  
  /**
   * Get consensus information for a block
   */
  getBlockConsensus(blockNumber) {
    return this.checkConsensus(blockNumber);
  }
  
  /**
   * Reward validator for participation
   */
  rewardValidator(validatorAddress, consensusReached) {
    const baseReward = 50; // 50 ZSNAIL base reward
    const consensusBonus = consensusReached ? 25 : 0; // 25 ZSNAIL bonus for consensus
    const totalReward = baseReward + consensusBonus;
    
    // Add reward to validator balance
    const currentBalance = this.getZSnailBalance(validatorAddress);
    this.setZSnailBalance(validatorAddress, (parseInt(currentBalance) + totalReward).toString());
    
    // Update validator reputation
    const validator = this.validators.get(validatorAddress);
    if (validator) {
      if (consensusReached) {
        validator.reputation = Math.min(100, validator.reputation + 1);
      }
    }
    
    // Track rewards
    if (!this.validationRewards.has(validatorAddress)) {
      this.validationRewards.set(validatorAddress, []);
    }
    
    this.validationRewards.get(validatorAddress).push({
      amount: totalReward,
      blockNumber: this.blockNumber,
      timestamp: Date.now(),
      consensusReached: consensusReached
    });
    
    return totalReward;
  }
  
  /**
   * Get validator rewards summary
   */
  getValidatorRewards(address) {
    const rewards = this.validationRewards.get(address) || [];
    const total = rewards.reduce((sum, r) => sum + r.amount, 0);
    
    const oneWeekAgo = Date.now() - (7 * 24 * 60 * 60 * 1000);
    const rewardsThisWeek = rewards
      .filter(r => r.timestamp > oneWeekAgo)
      .reduce((sum, r) => sum + r.amount, 0);
    
    const validator = this.validators.get(address);
    
    return {
      total: total,
      thisWeek: rewardsThisWeek,
      validations: rewards.length,
      reputation: validator ? validator.reputation : 0,
      nextEstimate: 50 // Base reward estimate
    };
  }
  
  // ========================================
  // TOKENOMICS HELPER FUNCTIONS
  // ========================================
  
  getTotalZSnailSupply() {
    // Calculate total supply based on all balances
    let total = 0;
    for (const balance of this.zsnailBalances.values()) {
      total += parseInt(balance);
    }
    return total.toString();
  }
  
  getCirculatingZSnailSupply() {
    // Circulating supply (excluding staked tokens)
    let circulating = 0;
    for (const [address, balance] of this.zsnailBalances.entries()) {
      if (!address.includes('POOL') && !address.includes('STAKE')) {
        circulating += parseInt(balance);
      }
    }
    return circulating.toString();
  }
  
  getTotalMinedRewards() {
    // Calculate total ETH mined
    return (BigInt(this.blockReward) * BigInt(this.blocks.length)).toString();
  }
  
  getTotalValidatorStake() {
    let totalStake = 0;
    for (const validator of this.validators.values()) {
      totalStake += parseInt(validator.stake);
    }
    return totalStake.toString();
  }
  
  getValidationRewardRate() {
    return '50'; // 50 ZSNAIL per validation
  }
}

// Initialize some ZSnail balances for testing
function initializeTestTokens(sequencer) {
  // Give the main wallet some ZSnail tokens for testing
  sequencer.initializeZSnailBalance('0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48', '10000000000000000000000000'); // 10M ZSNAIL
  
  console.log('🪙 Initialized test ZSnail tokens:');
  console.log('   Wallet: 0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48');
  console.log('   Balance: 10,000,000 ZSNAIL tokens');
  console.log('   Gas payments enabled with ZSnail tokens!');
}

// Start the sequencer
const sequencer = new ZSnailSequencer();

// Initialize test tokens
initializeTestTokens(sequencer);

// Start the blockchain
sequencer.start(8545);