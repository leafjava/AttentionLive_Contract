# Deployment Guide

## Prerequisites

1. Install Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

2. Install dependencies:
```bash
forge install OpenZeppelin/openzeppelin-contracts
```

## Configuration

1. Copy `.env.example` to `.env`:
```bash
cp .env.example .env
```

2. Fill in your private key and API keys in `.env`:
```env
PRIVATE_KEY=your_private_key_without_0x
BSCSCAN_API_KEY=your_bscscan_api_key
```

## Compile Contracts

```bash
forge build
```

## Run Tests

```bash
forge test -vvv
```

## Deploy to BSC Testnet

```bash
forge script script/DeployContracts.s.sol \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --broadcast \
  --verify \
  -vvvv
```

## After Deployment

1. Copy the deployed contract addresses from the console output
2. Update `AttentionLive/lib/contracts/staking.ts` with the new addresses:
   - ATTENTION_TOKEN_ADDRESS
   - STREAMER_STAKING_POOL_ADDRESS
   - VIEWER_REWARD_POOL_ADDRESS

3. Get testnet BNB from faucet:
   - https://testnet.bnbchain.org/faucet-smart

4. Test the contracts:
   - Mint some ATT tokens to your address
   - Approve and create a staking task
   - Test viewer reward claiming

## Verify Contracts (if auto-verify fails)

```bash
forge verify-contract \
  --chain-id 97 \
  --compiler-version v0.8.23 \
  <CONTRACT_ADDRESS> \
  src/AttentionToken.sol:AttentionToken \
  --etherscan-api-key $BSCSCAN_API_KEY
```

## Contract Addresses (BSC Testnet)

After deployment, update these addresses:

- AttentionToken: `0x...`
- StreamerStakingPool: `0x...`
- ViewerRewardPool: `0x...`

## Frontend Integration

1. Update contract addresses in `AttentionLive/lib/contracts/staking.ts`
2. Ensure ABIs are up to date in `AttentionLive/lib/abi/`
3. Test all staking flows:
   - Streamer: Approve → Create Task → End Task → Claim → Unstake
   - Viewer: Accumulate Points → Claim Rewards

## Troubleshooting

### Gas Issues
- Ensure you have enough testnet BNB
- Check gas price: https://testnet.bscscan.com/gastracker

### Transaction Fails
- Check contract state (task status, balances, allowances)
- Verify cooldown periods haven't expired
- Check minimum stake/claim amounts

### Verification Fails
- Wait a few minutes and try again
- Check constructor arguments match deployment
- Ensure correct compiler version (0.8.23)
