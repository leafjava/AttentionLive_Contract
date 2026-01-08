# AttentionLive Staking Contracts

Staking contracts for AttentionLive platform - a Watch-to-Earn live streaming incentive platform.

## Contracts

- **AttentionToken (ATT)**: Platform native ERC20 token with 18 decimals
- **StreamerStakingPool**: Staking pool for streamers to stake ATT tokens and earn rewards based on viewer engagement
- **ViewerRewardPool**: Reward distribution pool for viewers who complete watch tasks

## Core Features

### Streamer Staking
- Streamers stake ATT tokens to create live streaming tasks
- Minimum stake required to activate streaming
- Rewards distributed based on viewer engagement metrics
- Unstaking with cooldown period

### Viewer Rewards
- Viewers earn ATT tokens by completing watch tasks
- Verification code system to prevent fraud
- Points converted to ATT tokens
- Claim rewards anytime

### Reward Mechanism
- Streamer rewards: Based on total viewer engagement and verification rate
- Viewer rewards: Fixed points per verified watch session
- Platform fee: Small percentage for sustainability

## Deployment (BSC Testnet)

```bash
# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts

# Compile
forge build

# Test
forge test

# Deploy
export PRIVATE_KEY=0x...
forge script script/DeployContracts.s.sol --rpc-url bsc_testnet --broadcast -vvvv
```

## Contract Addresses (BSC Testnet, chainId 97)

Will be updated after deployment.

## Usage Flow

### For Streamers:
1. Approve ATT tokens to StreamerStakingPool
2. Call `createStreamingTask(amount, duration, rewardRate)` to stake and create task
3. Start live streaming and distribute verification codes
4. After streaming ends, call `claimStreamerReward(taskId)` to get rewards
5. Call `unstake(taskId)` to withdraw staked tokens (after cooldown)

### For Viewers:
1. Watch live stream and get verification code
2. Submit code through frontend (backend verifies and records points)
3. Call `claimViewerReward()` to convert points to ATT tokens
4. Tokens transferred to viewer's wallet

## Security Features

- ReentrancyGuard on all token transfer functions
- Ownable for admin functions
- Minimum stake requirements
- Cooldown periods for unstaking
- Verification system to prevent abuse

## Development

```bash
# Run tests
forge test -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage
```
