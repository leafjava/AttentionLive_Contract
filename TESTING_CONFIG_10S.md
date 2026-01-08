# 10秒测试配置说明

## ✅ 已完成的配置

所有时间参数已调整为 **10秒** 用于快速测试：

### 1. 合约配置 ✅
**文件**: `AttentionLive_contract/src/StreamerStakingPool.sol`

```solidity
// 最短任务持续时间: 10秒
require(duration >= 10, "Pool: min 10 seconds");

// Unstake 冷却期: 10秒
uint256 public unstakeCooldown = 10;
```

### 2. 前端配置 ✅
**文件**: `AttentionLive/app/(with-nav)/staking/page.tsx`

```typescript
// 默认任务持续时间: 10秒
const [duration, setDuration] = useState('10');
```

**文件**: `AttentionLive/lib/contracts/staking.ts`

```typescript
export const STAKING_CONFIG = {
  unstakeCooldown: 10, // 10 秒
  // ...
};
```

### 3. 文档更新 ✅
所有相关文档已更新，包括：
- ✅ `IMPLEMENTATION_COMPLETE.md`
- ✅ `FRONTEND_READY.md`
- ✅ `STAKING_QUICKSTART.md`
- ✅ `AttentionLive/STAKING_GUIDE.md`
- ✅ `AttentionLive/FRONTEND_TESTING.md`
- ✅ `AttentionLive_contract/PROJECT_SUMMARY.md`
- ✅ `AttentionLive_contract/QUICK_REDEPLOY.md`

## 🚀 如何使用

### 方式 1: 自然等待（推荐新手）

```bash
# 1. 创建任务（持续时间设为 10 秒）
# 2. 等待 10 秒
# 3. 点击 "End Task"
# 4. 点击 "Claim Reward"
# 5. 等待 10 秒
# 6. 点击 "Unstake"
```

**总耗时**: 约 20-30 秒

### 方式 2: 时间快进（最快）

```bash
# 创建任务后，立即快进
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545

# 点击 "End Task" 和 "Claim Reward" 后，再次快进
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545

# 点击 "Unstake"
```

**总耗时**: 约 10 秒

## 📝 完整测试流程

### 步骤 1: 准备
```bash
# 确保 Anvil 正在运行
cd AttentionLive_contract
anvil

# 确保前端正在运行
cd AttentionLive
pnpm dev
```

### 步骤 2: 创建任务
1. 访问 http://localhost:3000/staking
2. 连接 MetaMask 钱包
3. 输入质押金额（例如: 1000）
4. 持续时间设为 **10** 秒
5. 奖励率设为 500（5%）
6. 点击 "1. Approve ATT"
7. 点击 "2. Create Task"

### 步骤 3: 等待任务结束
**选项 A**: 等待 10 秒

**选项 B**: 使用时间快进
```bash
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545
```

### 步骤 4: 结束任务并领取奖励
1. 刷新页面（或等待自动刷新）
2. 在 "My Tasks" 中找到你的任务
3. 点击 "End Task" 按钮
4. 等待交易确认
5. 点击 "Claim Reward" 按钮

### 步骤 5: 等待冷却期
**选项 A**: 等待 10 秒

**选项 B**: 使用时间快进
```bash
cast rpc evm_increaseTime 11 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545
```

### 步骤 6: 取回质押
1. 刷新页面（或等待自动刷新）
2. 点击 "Unstake" 按钮
3. 完成！

## ⚠️ 重要提醒

### 需要重新部署合约
如果你之前部署的合约还是旧的配置（60分钟/7天），需要重新部署：

```bash
cd AttentionLive_contract

# 停止 Anvil (Ctrl + C)，然后重启
anvil

# 在新终端重新部署
forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

### 前端自动刷新
代码已添加自动刷新功能：
- End Task 成功后自动刷新任务列表
- Claim Reward 成功后自动刷新任务列表
- Unstake 成功后自动刷新任务列表

如果没有自动刷新，手动刷新浏览器即可。

## 🎯 测试目标

使用这个配置，你可以在 **30秒内** 完成完整的质押流程测试：
1. ✅ 创建任务
2. ✅ 结束任务
3. ✅ 领取奖励
4. ✅ 取回质押

## 🔄 恢复生产配置

当准备部署到测试网或主网时，记得改回生产配置：

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

## 📚 相关文档

- 完整部署指南: `AttentionLive_contract/QUICK_REDEPLOY.md`
- 前端测试指南: `AttentionLive/FRONTEND_TESTING.md`
- 质押指南: `AttentionLive/STAKING_GUIDE.md`
- 合约说明（中文）: `AttentionLive_contract/CONTRACT_EXPLANATION_CN.md`
