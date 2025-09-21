# 🦊 MetaMask Integration with ZSnail L2 Blockchain

Your ZSnail L2 Proof of Work blockchain is ready for MetaMask integration! Follow these steps to connect MetaMask to your custom blockchain.

## 🚀 Quick Setup

### Option 1: Automatic Setup (Recommended)
1. **Open the Integration Page**: Visit [http://localhost:8545/metamask](http://localhost:8545/metamask)
2. **Click "Add ZSnail L2 to MetaMask"** - This will automatically add the network
3. **Import Your Wallet** (see step 3 below)

### Option 2: Manual Setup
If the automatic setup doesn't work, add the network manually:

1. **Open MetaMask** and click on the network dropdown (top center)
2. **Click "Add Network"** → **"Add Network Manually"**
3. **Enter these details**:
   - **Network Name**: `ZSnail L2 Proof of Work`
   - **New RPC URL**: `http://localhost:8545`
   - **Chain ID**: `66875`
   - **Currency Symbol**: `ETH`
   - **Block Explorer URL**: (leave empty)

## 💰 Import Your Mining Wallet

Your wallet has been mining and accumulating ETH! Import it to see your balance:

1. **In MetaMask**: Click the account icon → **Import Account**
2. **Select**: Private Key
3. **Enter**: `f987f1cc01cec30d87b39f96e4610ee3400646df76f631d2ddf244eec2f178b7`
4. **Click Import**

**Your Wallet Address**: `0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48`

## ✅ Verify Connection

After setup, you should see:
- **Network**: ZSnail L2 Proof of Work (Chain ID: 66875)
- **Balance**: Your accumulated mining rewards (20+ ETH)
- **Account**: 0x9a36...3b48

## 🧪 Test Your Connection

1. **Check Balance**: You should see your mining rewards
2. **View Transactions**: Check the activity tab
3. **Send Test Transaction**: Try sending a small amount to test

## 📊 Blockchain Stats

Current ZSnail L2 Status:
- **Consensus**: Proof of Work (SHA256)
- **Block Time**: ~10-30 seconds (dynamic difficulty)
- **Current Difficulty**: Automatically adjusting
- **Mining Reward**: 1 ETH per block
- **Your Balance**: 20+ ETH (and growing!)

## 🔧 Troubleshooting

### MetaMask Not Connecting?
- Ensure the blockchain is running: `cd sequencer && node index.js`
- Check RPC URL: `http://localhost:8545`
- Verify Chain ID: `66875`

### Can't See Balance?
- Make sure you've imported the correct private key
- Refresh MetaMask
- Check you're on the ZSnail L2 network

### Network Not Appearing?
- Clear MetaMask cache
- Try the manual setup method
- Restart MetaMask

## 🎯 Next Steps

Once connected:
1. **Deploy Smart Contracts**: Use Foundry or Hardhat
2. **Build DApps**: Connect your web apps to ZSnail L2
3. **Experiment**: Test transactions, contracts, and DeFi protocols

## 📚 Advanced Features

Your ZSnail L2 blockchain supports:
- ✅ **Full EVM Compatibility**
- ✅ **MetaMask Integration**
- ✅ **Smart Contract Deployment**
- ✅ **Proof of Work Mining**
- ✅ **Dynamic Difficulty Adjustment**
- ✅ **JSON-RPC API**
- ✅ **Transaction Processing**

## 🔗 Useful Links

- **RPC Endpoint**: http://localhost:8545
- **Chain Info**: http://localhost:8545/info
- **Health Check**: http://localhost:8545/health
- **Wallet Info**: http://localhost:8545/wallet/0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48
- **MetaMask Setup**: http://localhost:8545/metamask

---

**🎉 Congratulations!** You now have a fully functional Proof of Work L2 blockchain with MetaMask integration!