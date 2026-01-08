#!/bin/bash

echo "🧪 AttentionLive Contract Testing Suite"
echo "========================================"
echo ""

# 检查 Foundry 是否安装
if ! command -v forge &> /dev/null; then
    echo "❌ Foundry not found. Please install it first:"
    echo "   curl -L https://foundry.paradigm.xyz | bash"
    echo "   foundryup"
    exit 1
fi

echo "✅ Foundry found: $(forge --version | head -n 1)"
echo ""

# 检查依赖
if [ ! -d "lib/openzeppelin-contracts" ]; then
    echo "📦 Installing OpenZeppelin contracts..."
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
    echo ""
fi

if [ ! -d "lib/forge-std" ]; then
    echo "📦 Installing forge-std..."
    forge install foundry-rs/forge-std --no-commit
    echo ""
fi

# 编译合约
echo "🔨 Compiling contracts..."
forge build
if [ $? -ne 0 ]; then
    echo "❌ Compilation failed"
    exit 1
fi
echo "✅ Compilation successful"
echo ""

# 运行测试
echo "🧪 Running tests..."
echo ""

# 基础测试
echo "--- Basic Tests ---"
forge test --match-contract StreamerStakingPoolTest -vv
echo ""

# 完整流程测试
echo "--- Full Flow Tests ---"
forge test --match-contract FullFlowTest -vvv
echo ""

# Gas 报告
echo "--- Gas Report ---"
forge test --gas-report
echo ""

echo "✅ All tests completed!"
echo ""
echo "📝 Next steps:"
echo "   1. Start local node: anvil"
echo "   2. Deploy contracts: forge script script/DeployContracts.s.sol --rpc-url http://127.0.0.1:8545 --broadcast"
echo "   3. Test with cast commands (see LOCAL_TESTING.md)"
