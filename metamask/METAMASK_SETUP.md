# 🦊 MetaMask Integration for ZSnail L2 Proof of Work Blockchain

## 🎯 Quick Setup Guide

### Method 1: Automatic Setup (Recommended)
1. **Start ZSnail L2 Blockchain** (if not already running):
   ```bash
   cd C:\Users\Josh\Desktop\Blockchain\sequencer
   node index.js
   ```

2. **Open the MetaMask Integration Page**:
   - Open: `C:\Users\Josh\Desktop\Blockchain\metamask\add-zsnail-to-metamask.html`
   - Click "Add to MetaMask" button
   - Follow the prompts

3. **Import Your Miner Wallet**:
   - Click "Import Miner Wallet" for instructions
   - Use the provided private key

### Method 2: Manual Setup

#### Step 1: Add ZSnail L2 Network to MetaMask

1. **Open MetaMask Extension**
2. **Click Network Dropdown** (usually shows "Ethereum Mainnet")
3. **Select "Add Network" or "Custom RPC"**
4. **Enter Network Details**:

   ```
   Network Name: ZSnail L2 Proof of Work
   New RPC URL: http://localhost:8545
   Chain ID: 66875
   Currency Symbol: ETH
   Block Explorer URL: http://localhost:8545/info
   ```

5. **Click "Save"**
6. **Switch to ZSnail L2 Network**

#### Step 2: Import Your Miner Wallet

1. **Click Your Account Avatar** in MetaMask
2. **Select "Import Account"**
3. **Choose "Private Key"**
4. **Paste Private Key**:
   ```
   f987f1cc01cec30d87b39f96e4610ee3400646df76f631d2ddf244eec2f178b7
   ```
5. **Click "Import"**

## 🔧 Network Configuration Details

| Setting | Value |
|---------|-------|
| **Network Name** | ZSnail L2 Proof of Work |
| **RPC URL** | http://localhost:8545 |
| **Chain ID** | 66875 (0x1053b) |
| **Currency Symbol** | ETH |
| **Currency Decimals** | 18 |
| **Block Explorer** | http://localhost:8545/info |
| **Consensus Mechanism** | Proof of Work |

## 👛 Wallet Information

### Your Miner Wallet
- **Address**: `0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48`
- **Private Key**: `f987f1cc01cec30d87b39f96e4610ee3400646df76f631d2ddf244eec2f178b7`
- **Role**: Primary miner earning all block rewards
- **Current Balance**: 50+ ETH (and growing with each mined block)

### ⚠️ Security Warning
**IMPORTANT**: This private key should ONLY be used on your local testnet! Never use test private keys on mainnet or share them publicly.

## 🎮 What You Can Do With MetaMask

### ✅ Supported Features:
- ✅ **View Account Balance** - See your mining rewards accumulate
- ✅ **View Transaction History** - Track blockchain activity
- ✅ **Send Transactions** - Transfer ETH between accounts
- ✅ **Deploy Smart Contracts** - Use Remix or Foundry
- ✅ **Interact with DApps** - Connect to your local applications
- ✅ **Monitor Network Stats** - Block numbers, difficulty, etc.

### 🔄 JSON-RPC Methods Supported:
- `eth_chainId` - Get chain ID (66875)
- `eth_blockNumber` - Get current block number
- `eth_getBalance` - Check wallet balance
- `eth_getTransactionCount` - Get nonce for transactions
- `eth_accounts` - List connected accounts
- `eth_gasPrice` - Get current gas price
- `eth_sendTransaction` - Send transactions
- `eth_estimateGas` - Estimate gas for transactions
- `net_version` - Network version
- `web3_clientVersion` - Client version

## 🚀 Testing Your Setup

### 1. Check Network Connection
```javascript
// Open browser console and run:
await ethereum.request({
  method: 'eth_chainId'
});
// Should return: "0x1053b" (66875 in hex)
```

### 2. Check Your Balance
```javascript
// Get your balance:
await ethereum.request({
  method: 'eth_getBalance',
  params: ['0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48', 'latest']
});
```

### 3. Get Current Block
```javascript
// Get current block number:
await ethereum.request({
  method: 'eth_blockNumber'
});
```

## 🔗 Useful Endpoints

| Endpoint | Purpose |
|----------|---------|
| http://localhost:8545/health | Blockchain health check |
| http://localhost:8545/info | Network information |
| http://localhost:8545/wallet/0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48 | Your wallet info |
| http://localhost:8545/wallets | All connected wallets |

## 🛠️ Troubleshooting

### Problem: MetaMask shows "Network Error"
**Solution**: Make sure ZSnail L2 blockchain is running on localhost:8545

### Problem: Can't see balance in MetaMask
**Solution**: 
1. Ensure you're connected to ZSnail L2 network
2. Check that you imported the correct private key
3. Refresh MetaMask or switch networks and back

### Problem: Transactions fail
**Solution**:
1. Check gas price is set correctly (1 gwei)
2. Ensure you have sufficient ETH balance
3. Verify you're on the correct network

### Problem: "Add Network" button doesn't work
**Solution**: Use manual setup method described above

## 🎯 Next Steps

1. **Deploy Smart Contracts**:
   ```bash
   forge create contracts/HelloZSnail.sol:HelloZSnail --rpc-url http://localhost:8545 --private-key f987f1cc01cec30d87b39f96e4610ee3400646df76f631d2ddf244eec2f178b7
   ```

2. **Create Additional Wallets**:
   - Generate new wallets in MetaMask
   - Transfer ETH from your miner wallet
   - Test transactions between wallets

3. **Build DApps**:
   - Use Web3.js or Ethers.js
   - Connect to your ZSnail L2 network
   - Deploy and interact with contracts

4. **Monitor Mining**:
   - Watch blocks being mined in real-time
   - See your balance increase with each block reward
   - Adjust mining difficulty if needed

## 🏆 Achievement Unlocked: Professional Blockchain Setup!

You now have:
- ✅ A live Proof of Work blockchain (ZSnail L2)
- ✅ MetaMask integration
- ✅ Mining rewards accumulating
- ✅ Full smart contract deployment capability
- ✅ Professional development environment

**Congratulations! Your ZSnail L2 blockchain is now fully integrated with MetaMask and ready for serious development work! 🎉**