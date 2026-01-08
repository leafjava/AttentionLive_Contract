#!/bin/bash

echo "Installing OpenZeppelin Contracts..."
forge install OpenZeppelin/openzeppelin-contracts --no-commit

echo "Building contracts..."
forge build

echo "Running tests..."
forge test

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Copy .env.example to .env and fill in your private key"
echo "2. Run: forge script script/DeployContracts.s.sol --rpc-url bsc_testnet --broadcast -vvvv"
echo "3. Update contract addresses in AttentionLive/lib/contracts/staking.ts"
