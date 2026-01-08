#!/bin/bash

echo "🚀 Local Deployment Script"
echo "=========================="
echo ""

# Anvil 默认账户私钥
DEPLOYER_KEY="0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"
RPC_URL="http://127.0.0.1:8545"

echo "📋 Configuration:"
echo "   RPC URL: $RPC_URL"
echo "   Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
echo ""

# 检查 Anvil 是否运行
echo "🔍 Checking if Anvil is running..."
if ! curl -s -X POST -H "Content-Type: application/json" --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' $RPC_URL > /dev/null; then
    echo "❌ Anvil is not running!"
    echo ""
    echo "Please start Anvil in another terminal:"
    echo "   anvil"
    echo ""
    exit 1
fi
echo "✅ Anvil is running"
echo ""

# 部署合约
echo "🚀 Deploying contracts..."
forge script script/DeployContracts.s.sol \
  --rpc-url $RPC_URL \
  --private-key $DEPLOYER_KEY \
  --broadcast \
  -vvv

if [ $? -ne 0 ]; then
    echo "❌ Deployment failed"
    exit 1
fi

echo ""
echo "✅ Deployment successful!"
echo ""
echo "📝 Next steps:"
echo "   1. Copy the contract addresses from above"
echo "   2. Update AttentionLive/lib/contracts/staking.ts"
echo "   3. Run interaction tests: ./interact.sh"
echo "   4. Or use cast commands manually (see LOCAL_TESTING.md)"
