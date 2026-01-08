#!/bin/bash

# Sepolia 测试网部署脚本
# 使用方法: ./deploy-sepolia.sh

echo "================================"
echo "部署到 Sepolia 测试网"
echo "================================"
echo ""

# 检查 .env 文件是否存在
if [ ! -f .env ]; then
    echo "❌ 错误: .env 文件不存在"
    echo "请先创建 .env 文件并配置以下变量："
    echo "  - PRIVATE_KEY"
    echo "  - SEPOLIA_RPC_URL"
    echo "  - ETHERSCAN_API_KEY"
    echo ""
    echo "可以从 .env.example 复制："
    echo "  cp .env.example .env"
    exit 1
fi

# 加载环境变量
source .env

# 检查必需的环境变量
if [ -z "$PRIVATE_KEY" ]; then
    echo "❌ 错误: PRIVATE_KEY 未设置"
    exit 1
fi

if [ -z "$SEPOLIA_RPC_URL" ]; then
    echo "❌ 错误: SEPOLIA_RPC_URL 未设置"
    exit 1
fi

# 获取部署者地址
DEPLOYER=$(cast wallet address --private-key $PRIVATE_KEY)
echo "📍 部署者地址: $DEPLOYER"

# 检查余额
BALANCE=$(cast balance $DEPLOYER --rpc-url $SEPOLIA_RPC_URL)
BALANCE_ETH=$(cast --to-unit $BALANCE ether)
echo "💰 账户余额: $BALANCE_ETH ETH"

# 检查余额是否足够（至少 0.05 ETH）
MIN_BALANCE="50000000000000000" # 0.05 ETH in wei
if [ $(echo "$BALANCE < $MIN_BALANCE" | bc) -eq 1 ]; then
    echo "⚠️  警告: 余额可能不足，建议至少 0.1 ETH"
    echo "从水龙头获取测试币: https://sepoliafaucet.com/"
    read -p "是否继续部署? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

echo ""
echo "🔨 开始编译合约..."
forge build

if [ $? -ne 0 ]; then
    echo "❌ 编译失败"
    exit 1
fi

echo ""
echo "✅ 编译成功"
echo ""
echo "🚀 开始部署到 Sepolia..."
echo ""

# 部署合约
forge script script/DeployContracts.s.sol \
    --rpc-url sepolia \
    --broadcast \
    --verify \
    -vvvv

if [ $? -eq 0 ]; then
    echo ""
    echo "================================"
    echo "✅ 部署成功！"
    echo "================================"
    echo ""
    echo "📝 下一步操作："
    echo "1. 查看部署日志，记录合约地址"
    echo "2. 在 Sepolia Etherscan 上查看合约"
    echo "3. 更新前端配置文件: AttentionLive/lib/contracts/staking.ts"
    echo "4. 在 MetaMask 中添加 ATT 代币"
    echo ""
    echo "🔗 Sepolia Etherscan: https://sepolia.etherscan.io/"
    echo ""
else
    echo ""
    echo "❌ 部署失败"
    echo "请检查错误信息并重试"
    exit 1
fi
