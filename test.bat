@echo off
echo 🧪 AttentionLive Contract Testing Suite
echo ========================================
echo.

REM 检查 Foundry 是否安装
where forge >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Foundry not found. Please install it first:
    echo    curl -L https://foundry.paradigm.xyz ^| bash
    echo    foundryup
    exit /b 1
)

echo ✅ Foundry found
forge --version | findstr /C:"forge"
echo.

REM 检查依赖
if not exist "lib\openzeppelin-contracts" (
    echo 📦 Installing OpenZeppelin contracts...
    forge install OpenZeppelin/openzeppelin-contracts --no-commit
    echo.
)

if not exist "lib\forge-std" (
    echo 📦 Installing forge-std...
    forge install foundry-rs/forge-std --no-commit
    echo.
)

REM 编译合约
echo 🔨 Compiling contracts...
forge build
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Compilation failed
    exit /b 1
)
echo ✅ Compilation successful
echo.

REM 运行测试
echo 🧪 Running tests...
echo.

echo --- Basic Tests ---
forge test --match-contract StreamerStakingPoolTest -vv
echo.

echo --- Full Flow Tests ---
forge test --match-contract FullFlowTest -vvv
echo.

echo --- Gas Report ---
forge test --gas-report
echo.

echo ✅ All tests completed!
echo.
echo 📝 Next steps:
echo    1. Start local node: anvil
echo    2. Deploy contracts: forge script script/DeployContracts.s.sol --rpc-url http://127.0.0.1:8545 --broadcast
echo    3. Test with cast commands (see LOCAL_TESTING.md)

pause
