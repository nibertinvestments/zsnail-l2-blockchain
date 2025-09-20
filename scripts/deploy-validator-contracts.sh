#!/bin/bash

# ZSnail L2 Native Token & Validator Infrastructure Deployment
# Deploy the backbone ZSNAIL token (like ETH on Ethereum)

set -e

echo "� Deploying ZSnail L2 Native Token Infrastructure..."
echo "===================================================="

# Configuration
RPC_URL="http://34.122.156.185:8545"
CHAIN_ID="66875"
PRIVATE_KEY="f987f1cc01cec30d87b39f96e4610ee3400646df76f631d2ddf244eec2f178b7"

# Native token configuration
MIN_STAKE="50000000000000000000000"  # 50,000 ZSNAIL tokens
CONSENSUS_THRESHOLD="67"             # 67% consensus requirement
DEPLOYER_ADDRESS="0x9a36a3e13586f6b114aA78fD84b6fe6055f83b48"
TREASURY_ADDRESS="$DEPLOYER_ADDRESS"  # Treasury address (can be DAO later)
SEQUENCER_ADDRESS="$DEPLOYER_ADDRESS" # Sequencer address

echo "📋 Configuration:"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Min Validator Stake: 50,000 ZSNAIL"
echo "   Consensus Threshold: $CONSENSUS_THRESHOLD%"
echo "   Treasury Address: $TREASURY_ADDRESS"
echo ""

# 1. Deploy ZSnail Native Token (the backbone of the blockchain)
echo "1️⃣ Deploying ZSnail Native Token (Blockchain Backbone)..."
ZSNAIL_NATIVE_TOKEN_ADDRESS=$(forge create contracts/ZSnailNativeToken.sol:ZSnailNativeToken \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args "$TREASURY_ADDRESS" "$SEQUENCER_ADDRESS" "$DEPLOYER_ADDRESS" \
    --json | jq -r '.deployedTo')

if [ "$ZSNAIL_NATIVE_TOKEN_ADDRESS" != "null" ] && [ -n "$ZSNAIL_NATIVE_TOKEN_ADDRESS" ]; then
    echo "✅ ZSnail Native Token deployed: $ZSNAIL_NATIVE_TOKEN_ADDRESS"
else
    echo "❌ ZSnail Native Token deployment failed"
    exit 1
fi

echo ""

# 2. Deploy Validator Registry (works with native ZSNAIL)
echo "2️⃣ Deploying Validator Registry..."
VALIDATOR_REGISTRY_ADDRESS=$(forge create contracts/ValidatorRegistry.sol:ValidatorRegistry \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args "$ZSNAIL_NATIVE_TOKEN_ADDRESS" "$MIN_STAKE" "$CONSENSUS_THRESHOLD" "$DEPLOYER_ADDRESS" \
    --json | jq -r '.deployedTo')

if [ "$VALIDATOR_REGISTRY_ADDRESS" != "null" ] && [ -n "$VALIDATOR_REGISTRY_ADDRESS" ]; then
    echo "✅ Validator Registry deployed: $VALIDATOR_REGISTRY_ADDRESS"
else
    echo "❌ Validator Registry deployment failed"
    exit 1
fi

echo ""

# 3. Deploy Oracle Registry
echo "3️⃣ Deploying Oracle Registry..."
ORACLE_REGISTRY_ADDRESS=$(forge create contracts/OracleRegistry.sol:OracleRegistry \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args "$DEPLOYER_ADDRESS" \
    --json | jq -r '.deployedTo')

if [ "$ORACLE_REGISTRY_ADDRESS" != "null" ] && [ -n "$ORACLE_REGISTRY_ADDRESS" ]; then
    echo "✅ Oracle Registry deployed: $ORACLE_REGISTRY_ADDRESS"
else
    echo "❌ Oracle Registry deployment failed"
    exit 1
fi

echo ""

# 4. Connect Native Token to Validator Registry
echo "4️⃣ Connecting Native Token to Validator Registry..."
cast send $ZSNAIL_NATIVE_TOKEN_ADDRESS \
    "setValidatorRegistry(address)" \
    $VALIDATOR_REGISTRY_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

echo "✅ Native Token connected to Validator Registry"
echo ""

# Save contract addresses
echo "📝 Saving contract addresses..."
cat > contracts/deployed-native-addresses.json << EOF
{
  "chainId": "$CHAIN_ID",
  "rpcUrl": "$RPC_URL",
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "nativeToken": {
    "ZSnailNativeToken": "$ZSNAIL_NATIVE_TOKEN_ADDRESS",
    "isNativeBlockchainToken": true,
    "symbol": "ZSNAIL",
    "maxSupply": "210000000000000000000000000000",
    "initialSupply": "100000000000000000000000000",
    "blockReward": "50000000000000000000",
    "halvingInterval": 525600
  },
  "contracts": {
    "ValidatorRegistry": "$VALIDATOR_REGISTRY_ADDRESS",
    "OracleRegistry": "$ORACLE_REGISTRY_ADDRESS"
  },
  "configuration": {
    "minValidatorStake": "$MIN_STAKE",
    "consensusThreshold": "$CONSENSUS_THRESHOLD",
    "treasuryAddress": "$TREASURY_ADDRESS",
    "sequencerAddress": "$SEQUENCER_ADDRESS"
  }
}
EOF

echo "✅ Contract addresses saved to contracts/deployed-native-addresses.json"
echo ""

# Verify deployments
echo "🔍 Verifying Native Token deployment..."

# Test Native Token
echo "   Testing ZSnail Native Token..."
TOKEN_NAME=$(cast call $ZSNAIL_NATIVE_TOKEN_ADDRESS "name()" --rpc-url $RPC_URL)
TOKEN_SYMBOL=$(cast call $ZSNAIL_NATIVE_TOKEN_ADDRESS "symbol()" --rpc-url $RPC_URL)
MAX_SUPPLY=$(cast call $ZSNAIL_NATIVE_TOKEN_ADDRESS "maxSupply()" --rpc-url $RPC_URL)
CURRENT_REWARD=$(cast call $ZSNAIL_NATIVE_TOKEN_ADDRESS "getCurrentBlockReward()" --rpc-url $RPC_URL)

echo "   ✅ Token Name: $TOKEN_NAME"
echo "   ✅ Token Symbol: $TOKEN_SYMBOL"
echo "   ✅ Max Supply: $MAX_SUPPLY ZSNAIL"
echo "   ✅ Current Block Reward: $CURRENT_REWARD ZSNAIL"

# Test Validator Registry
echo "   Testing Validator Registry..."
MIN_STAKE_CHECK=$(cast call $VALIDATOR_REGISTRY_ADDRESS "minStake()" --rpc-url $RPC_URL)
ACTIVE_VALIDATORS=$(cast call $VALIDATOR_REGISTRY_ADDRESS "getActiveValidatorCount()" --rpc-url $RPC_URL)

echo "   ✅ Validator Registry Min Stake: $MIN_STAKE_CHECK"
echo "   ✅ Active Validators: $ACTIVE_VALIDATORS"

# Test Oracle Registry
echo "   Testing Oracle Registry..."
ORACLE_COUNT=$(cast call $ORACLE_REGISTRY_ADDRESS "getActiveOracleCount()" --rpc-url $RPC_URL)
echo "   ✅ Oracle Registry Active Oracles: $ORACLE_COUNT"

echo ""
echo "🎉 ZSnail Native Token Infrastructure Deployed Successfully!"
echo ""
echo "📋 Summary:"
echo "   🐌 ZSnail Native Token:  $ZSNAIL_NATIVE_TOKEN_ADDRESS"
echo "   ⚡ Validator Registry:   $VALIDATOR_REGISTRY_ADDRESS"
echo "   📊 Oracle Registry:      $ORACLE_REGISTRY_ADDRESS"
echo ""
echo "🔧 Native Token Features:"
echo "   💰 Max Supply: 210 billion ZSNAIL (Bitcoin-like)"
echo "   ⛏️  Block Reward: 50 ZSNAIL per block"
echo "   📈 Halving: Every 525,600 blocks (~3 years)"
echo "   🏦 Treasury: 10% of rewards"
echo "   ⚡ Validators: 20% of rewards"
echo "   ⛏️  Miners: 70% of rewards"
echo ""
echo "🎯 Next Steps:"
echo "   1. Register as first validator with 50,000 ZSNAIL stake"
echo "   2. Deploy validator node infrastructure"
echo "   3. Deploy oracle nodes for price feeds"
echo "   4. Update sequencer to use native ZSNAIL for gas"
echo ""

# Register deployer as first validator (using native ZSNAIL)
echo "🏁 Registering deployer as first validator with native ZSNAIL stake..."

# Check if we have enough ZSNAIL for staking (this would come from the initial treasury allocation)
BALANCE=$(cast balance $DEPLOYER_ADDRESS --rpc-url $RPC_URL)
echo "   Current ETH balance: $BALANCE wei"

# In a real scenario, we'd need to fund the deployer address with ZSNAIL from the treasury
# For now, let's document this step
echo ""
echo "📝 Manual Step Required:"
echo "   The deployer needs to receive ZSNAIL from the treasury to stake as a validator."
echo "   This should be done through the native token's treasury distribution function."
echo ""
echo "🎯 ZSnail L2 Native Token Infrastructure Ready!"
echo "   The blockchain now has its native ZSNAIL token as the backbone currency!"