# 快速重新部署指南

## 🎯 修改内容

已将测试时间从生产环境调整为快速测试：

1. **任务最短持续时间**: 5分钟 → **10秒**
2. **Unstake 冷却期**: 7天 → **10秒**
3. **前端默认持续时间**: 3600秒 → **10秒**

## 📋 重新部署步骤

### 1. 停止当前的 Anvil 节点
在运行 `anvil` 的终端按 `Ctrl + C` 停止

### 2. 重新启动 Anvil
```bash
cd AttentionLive_contract
anvil
```

### 3. 重新部署合约
在新终端窗口：

```bash
cd AttentionLive_contract

forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

### 4. 记录新的合约地址
部署输出会显示：
```
AttentionToken deployed at: 0x...
StreamerStakingPool deployed at: 0x...
ViewerRewardPool deployed at: 0x...
```

### 5. 更新前端配置（如果地址变了）
编辑 `AttentionLive/lib/contracts/staking.ts`，更新合约地址。

### 6. 重启前端
```bash
cd AttentionLive
# 如果前端正在运行，按 Ctrl + C 停止
pnpm dev
```

### 7. 刷新浏览器
访问 http://localhost:3000/staking

## 🧪 新的测试流程

现在测试超快！

### 完整流程（约 30 秒）

1. **创建任务** (10秒)
   - Approve ATT
   - Create Task (持续时间: 10秒)

2. **等待 10 秒** ⏱️
   - 或使用时间快进

3. **结束任务** (5秒)
   - 点击 "End Task"

4. **领取奖励** (5秒)
   - 点击 "Claim Reward"

5. **等待 10 秒** ⏱️
   - 或使用时间快进

6. **取回质押** (5秒)
   - 点击 "Unstake"

### 使用时间快进（秒级测试）

如果连 10 秒都不想等：

```bash
# 快进 11 秒（任务结束）
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545

# 结束任务 + 领取奖励后，再快进 11 秒
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545
```

## ⚠️ 注意事项

### 这是测试配置
- **不要用于生产环境！**
- 生产环境应该使用：
  - 最短持续时间: 5分钟或更长
  - Unstake 冷却期: 7天或更长

### 当前测试配置

```solidity
// StreamerStakingPool.sol
uint256 public unstakeCooldown = 10; // 10 秒
require(duration >= 10, "Pool: min 10 seconds"); // 10 秒
```

### 恢复生产配置
如果要部署到测试网或主网，记得改回：

```solidity
// StreamerStakingPool.sol
uint256 public unstakeCooldown = 7 days;
require(duration >= 300, "Pool: min 5 minutes");
```

```typescript
// staking/page.tsx
const [duration, setDuration] = useState('3600');

// staking.ts
unstakeCooldown: 7 * 24 * 60 * 60,
```

## 🎉 开始测试

重新部署后，你就可以快速测试完整流程了！
