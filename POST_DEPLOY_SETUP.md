# 部署后配置指南

## 📋 部署成功后的必要步骤

### 1. 记录合约地址

部署成功后，终端会显示类似输出：

```
=== Deployment Summary ===
AttentionToken: 0x1234567890abcdef1234567890abcdef12345678
StreamerStakingPool: 0xabcdef1234567890abcdef1234567890abcdef12
ViewerRewardPool: 0x567890abcdef1234567890abcdef1234567890ab
Deployer: 0xdef1234567890abcdef1234567890abcdef12345
```

**请立即保存这些地址！**

可以创建一个 `deployed-addresses.txt` 文件：

```bash
# Sepolia Testnet Deployment
Date: 2024-XX-XX
Network: Sepolia (Chain ID: 11155111)

AttentionToken: 0x...
StreamerStakingPool: 0x...
ViewerRewardPool: 0x...
Deployer: 0x...

Etherscan Links:
- ATT: https://sepolia.etherscan.io/address/0x...
- Staking Pool: https://sepolia.etherscan.io/address/0x...
- Reward Pool: https://sepolia.etherscan.io/address/0x...
```

---

## 🔧 更新前端配置

### 步骤 1: 更新合约地址

编辑 `AttentionLive/lib/contracts/staking.ts`：

```typescript
// Sepolia Testnet (chainId 11155111)
export const ATTENTION_TOKEN_ADDRESS = "0x你的ATT合约地址" as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0x你的质押池地址" as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x你的奖励池地址" as `0x${string}`;

// Contract configuration
export const STAKING_CONFIG = {
  minStakeAmount: "1000", // 1000 ATT
  unstakeCooldown: 10, // 10 秒（测试配置）
  platformFeeRate: 500, // 5% = 500 basis points
  pointsPerToken: 1000, // 1000 points = 1 ATT
  minClaimPoints: 1000, // Minimum 1000 points to claim
  claimCooldown: 60 * 60, // 1 hour in seconds
};
```

### 步骤 2: 更新网络配置

编辑 `AttentionLive/config/wagmi.ts`：

```typescript
import { http, createConfig } from 'wagmi';
import { sepolia } from 'wagmi/chains';
import { injected, metaMask } from 'wagmi/connectors';

export const config = createConfig({
  chains: [sepolia],
  connectors: [
    injected(),
    metaMask(),
  ],
  transports: {
    [sepolia.id]: http(),
  },
});
```

**如果需要同时支持本地和 Sepolia：**

```typescript
import { localhost, sepolia } from 'wagmi/chains';

export const config = createConfig({
  chains: [localhost, sepolia],
  connectors: [
    injected(),
    metaMask(),
  ],
  transports: {
    [localhost.id]: http('http://127.0.0.1:8545'),
    [sepolia.id]: http(),
  },
});
```

### 步骤 3: 更新 ConnectWallet 组件

编辑 `AttentionLive/components/ConnectWallet.tsx`，确保支持 Sepolia：

```typescript
// 检查是否在正确的网络
const isSepolia = chain?.id === 11155111;

if (!isSepolia) {
  // 提示用户切换到 Sepolia
  await switchChain({ chainId: 11155111 });
}
```

---

## 🦊 MetaMask 配置

### 1. 添加 Sepolia 网络

**自动添加（推荐）：**
1. 打开 MetaMask
2. 点击网络下拉菜单
3. 点击"添加网络"
4. 选择"Sepolia 测试网络"

**手动添加：**
- 网络名称: `Sepolia`
- RPC URL: `https://rpc.sepolia.org`
- 链 ID: `11155111`
- 货币符号: `ETH`
- 区块浏览器: `https://sepolia.etherscan.io`

### 2. 添加 ATT 代币

**方式 1: 通过前端自动添加**

在你的前端添加一个"添加 ATT 到钱包"按钮：

```typescript
const addTokenToWallet = async () => {
  try {
    await window.ethereum.request({
      method: 'wallet_watchAsset',
      params: {
        type: 'ERC20',
        options: {
          address: ATTENTION_TOKEN_ADDRESS,
          symbol: 'ATT',
          decimals: 18,
          image: 'https://your-domain.com/att-logo.png', // 可选
        },
      },
    });
  } catch (error) {
    console.error('Failed to add token:', error);
  }
};
```

**方式 2: 手动添加**

1. 在 MetaMask 中点击"导入代币"
2. 选择"自定义代币"
3. 输入 ATT 合约地址: `0x你的ATT地址`
4. 代币符号会自动填充为 `ATT`
5. 小数位数会自动填充为 `18`
6. 点击"添加"

---

## 🧪 测试部署

### 1. 检查合约在 Etherscan 上

访问以下链接，确认合约已验证：

- ATT Token: `https://sepolia.etherscan.io/address/你的ATT地址`
- Staking Pool: `https://sepolia.etherscan.io/address/你的质押池地址`
- Reward Pool: `https://sepolia.etherscan.io/address/你的奖励池地址`

**验证成功的标志：**
- ✅ 显示绿色对勾
- ✅ 可以看到"Contract"标签
- ✅ 可以查看源代码
- ✅ 可以直接在 Etherscan 上调用合约函数

### 2. 检查代币余额

在 Etherscan 上查看各个地址的 ATT 余额：

- **部署者地址**: 应该有剩余的 ATT（100M - 15M = 85M ATT）
- **Staking Pool**: 应该有 5M ATT
- **Reward Pool**: 应该有 10M ATT

### 3. 测试前端连接

```bash
cd AttentionLive
pnpm dev
```

访问 http://localhost:3000/staking

**测试清单：**
- [ ] 能够连接 MetaMask（Sepolia 网络）
- [ ] 能够看到 ATT 余额
- [ ] 能够看到合约配置信息
- [ ] 能够 Approve ATT
- [ ] 能够创建质押任务

---

## 🎯 完整测试流程

### 准备工作

1. 确保 MetaMask 连接到 Sepolia 网络
2. 确保钱包有足够的 SepoliaETH（至少 0.01 ETH）
3. 确保钱包有 ATT 代币（从部署者地址转一些）

### 主播测试流程

```bash
# 1. 转一些 ATT 给测试账户
# 在 Etherscan 上或通过前端转账

# 2. 访问质押页面
http://localhost:3000/staking

# 3. 连接钱包（Sepolia）

# 4. 创建质押任务
- 质押金额: 1000 ATT
- 持续时间: 10 秒
- 奖励率: 500 (5%)

# 5. Approve ATT
点击 "1. Approve ATT" 按钮

# 6. Create Task
点击 "2. Create Task" 按钮

# 7. 等待 10 秒（或使用时间快进）
# 注意：Sepolia 不支持 evm_increaseTime，需要真实等待

# 8. End Task
点击 "End Task" 按钮

# 9. Claim Reward
点击 "Claim Reward" 按钮

# 10. 等待 10 秒

# 11. Unstake
点击 "Unstake" 按钮
```

### 观众测试流程

观众功能需要后端支持，暂时可以通过 Etherscan 手动测试：

1. 访问 ViewerRewardPool 合约页面
2. 点击"Write Contract"
3. 连接钱包（需要是合约 owner）
4. 调用 `addPoints` 函数添加积分
5. 切换到观众账户
6. 调用 `claimReward` 函数兑换代币

---

## 📊 监控和维护

### 1. 监控合约余额

定期检查合约余额，确保有足够的代币用于奖励：

```bash
# 检查 Staking Pool 余额
cast balance <StakingPool地址> --rpc-url sepolia

# 检查 Reward Pool 余额
cast balance <RewardPool地址> --rpc-url sepolia
```

### 2. 查看合约事件

在 Etherscan 上查看合约事件日志：

- 任务创建事件 (TaskCreated)
- 任务结束事件 (TaskEnded)
- 奖励领取事件 (RewardClaimed)
- 质押取回事件 (Unstaked)

### 3. 管理员操作

如果需要调整参数，可以通过 Etherscan 调用管理函数：

**StreamerStakingPool:**
- `setMinStakeAmount(uint256)` - 调整最低质押金额
- `setUnstakeCooldown(uint256)` - 调整冷却期
- `setPlatformFeeRate(uint256)` - 调整手续费率
- `setFeeCollector(address)` - 更改手续费收集地址

**ViewerRewardPool:**
- `setPointsPerToken(uint256)` - 调整兑换率
- `setMinClaimPoints(uint256)` - 调整最低兑换积分
- `setClaimCooldown(uint256)` - 调整兑换冷却期

---

## 🔄 重新部署

如果需要重新部署（例如修复 bug 或更新功能）：

### 1. 修改合约代码

编辑 `src/` 目录下的合约文件

### 2. 运行测试

```bash
forge test
```

### 3. 重新部署

```bash
# Windows
deploy-sepolia.bat

# Mac/Linux
./deploy-sepolia.sh
```

### 4. 更新前端配置

使用新的合约地址更新 `staking.ts`

### 5. 通知用户

如果有用户在使用旧合约：
- 发布公告说明新合约地址
- 提供迁移指南
- 考虑实现合约升级机制（使用代理模式）

---

## 🚨 紧急情况处理

### 合约出现问题

1. **暂停功能**（如果实现了 Pausable）
2. **停止前端访问**
3. **分析问题**
4. **修复并重新部署**
5. **通知用户**

### 资金不足

如果奖励池代币不足：

```bash
# 从部署者地址转入更多 ATT
cast send <RewardPool地址> \
  "depositTokens(uint256)" \
  <金额> \
  --rpc-url sepolia \
  --private-key $PRIVATE_KEY
```

---

## 📝 文档和记录

建议维护以下文档：

1. **部署记录**: 记录每次部署的时间、地址、版本
2. **变更日志**: 记录合约的修改历史
3. **测试报告**: 记录测试结果和发现的问题
4. **用户指南**: 为用户提供使用说明
5. **API 文档**: 如果有后端 API，提供文档

---

## ✅ 部署检查清单

部署完成后，确认以下所有项目：

- [ ] 合约已成功部署到 Sepolia
- [ ] 合约已在 Etherscan 上验证
- [ ] 合约地址已记录并备份
- [ ] 前端配置已更新（staking.ts）
- [ ] 网络配置已更新（wagmi.ts）
- [ ] MetaMask 已添加 Sepolia 网络
- [ ] MetaMask 已添加 ATT 代币
- [ ] 奖励池已充值（10M ATT）
- [ ] 质押池已充值（5M ATT）
- [ ] 前端可以正常连接合约
- [ ] 完整流程测试通过
- [ ] 文档已更新
- [ ] 团队成员已通知

---

## 🎉 完成！

恭喜！你的 AttentionLive 合约已成功部署到 Sepolia 测试网并完成配置。

**下一步：**
- 邀请团队成员测试
- 收集反馈并改进
- 准备主网部署（如果需要）
- 考虑安全审计

祝项目顺利！🚀
