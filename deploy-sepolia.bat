@echo off
REM Sepolia 测试网部署脚本 (Windows)
REM 使用方法: deploy-sepolia.bat

echo ================================
echo 部署到 Sepolia 测试网
echo ================================
echo.

REM 检查 .env 文件是否存在
if not exist .env (
    echo ❌ 错误: .env 文件不存在
    echo 请先创建 .env 文件并配置以下变量：
    echo   - PRIVATE_KEY
    echo   - SEPOLIA_RPC_URL
    echo   - ETHERSCAN_API_KEY
    echo.
    echo 可以从 .env.example 复制：
    echo   copy .env.example .env
    exit /b 1
)

echo 🔨 开始编译合约...
forge build

if errorlevel 1 (
    echo ❌ 编译失败
    exit /b 1
)

echo.
echo ✅ 编译成功
echo.
echo 🚀 开始部署到 Sepolia...
echo.

REM 部署合约
forge script script/DeployContracts.s.sol --rpc-url sepolia --broadcast --verify -vvvv

if errorlevel 1 (
    echo.
    echo ❌ 部署失败
    echo 请检查错误信息并重试
    exit /b 1
)

echo.
echo ================================
echo ✅ 部署成功！
echo ================================
echo.
echo 📝 下一步操作：
echo 1. 查看部署日志，记录合约地址
echo 2. 在 Sepolia Etherscan 上查看合约
echo 3. 更新前端配置文件: AttentionLive/lib/contracts/staking.ts
echo 4. 在 MetaMask 中添加 ATT 代币
echo.
echo 🔗 Sepolia Etherscan: https://sepolia.etherscan.io/
echo.

pause
