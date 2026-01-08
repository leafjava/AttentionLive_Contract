@echo off
echo 🚀 Local Deployment Script
echo ==========================
echo.

REM Anvil 默认账户私钥
set DEPLOYER_KEY=0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
set RPC_URL=http://127.0.0.1:8545

echo 📋 Configuration:
echo    RPC URL: %RPC_URL%
echo    Deployer: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
echo.

REM 检查 Anvil 是否运行
echo 🔍 Checking if Anvil is running...
curl -s -X POST -H "Content-Type: application/json" --data "{\"jsonrpc\":\"2.0\",\"method\":\"eth_blockNumber\",\"params\":[],\"id\":1}" %RPC_URL% >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Anvil is not running!
    echo.
    echo Please start Anvil in another terminal:
    echo    anvil
    echo.
    pause
    exit /b 1
)
echo ✅ Anvil is running
echo.

REM 部署合约
echo 🚀 Deploying contracts...
set PRIVATE_KEY=%DEPLOYER_KEY%
forge script script/DeployContracts.s.sol --rpc-url %RPC_URL% --broadcast -vvv

if %ERRORLEVEL% NEQ 0 (
    echo ❌ Deployment failed
    pause
    exit /b 1
)

echo.
echo ✅ Deployment successful!
echo.
echo 📝 Next steps:
echo    1. Copy the contract addresses from above
echo    2. Update AttentionLive/lib/contracts/staking.ts
echo    3. Use cast commands to interact (see LOCAL_TESTING.md)

pause
