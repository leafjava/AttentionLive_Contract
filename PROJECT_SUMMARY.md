# AttentionLive Staking System - Project Summary

## 项目概述

为 AttentionLive 直播平台添加了完整的质押功能，包括智能合约和前端集成。

## 架构设计

### 智能合约层 (AttentionLive_contract)

```
AttentionLive_contract/
├── src/
│   ├── AttentionToken.sol           # ATT 代币合约
│   ├── StreamerStakingPool.sol      # 主播质押池
│   └── ViewerRewardPool.sol         # 观众奖励池
├── script/
│   └── DeployContracts.s.sol        # 部署脚本
├── test/
│   └── StreamerStakingPool.t.sol    # 测试用例
└── foundry.toml                      # Foundry 配置
```

#### 核心合约功能

**1. AttentionToken (ATT)**
- ERC20 标准代币
- 18 位小数
- 初始供应量：100,000,000 ATT
- 支持铸造和销毁

**2. StreamerStakingPool**
- 主播质押 ATT 创建直播任务
- 基于观众参与度计算奖励
- 7天提取冷却期
- 5% 平台手续费

**3. ViewerRewardPool**
- 观众积分管理
- 积分兑换 ATT 代币（1000:1）
- 1小时兑换冷却期
- 批量添加积分功能

### 前端层 (AttentionLive)

```
AttentionLive/
├── app/(with-nav)/
│   └── staking/
│       ├── page.tsx                 # 质押主页
│       └── my-tasks/page.tsx        # 我的任务
├── lib/
│   ├── contracts/
│   │   └── staking.ts               # 合约地址配置
│   └── abi/
│       ├── AttentionToken.json      # ATT ABI
│       ├── StreamerStakingPool.json # 质押池 ABI
│       └── ViewerRewardPool.json    # 奖励池 ABI
└── types/
    └── attention.ts                  # 类型定义
```

## 业务流程

### 主播质押流程

```mermaid
graph LR
    A[连接钱包] --> B[授权 ATT]
    B --> C[创建任务]
    C --> D[开始直播]
    D --> E[分发验证码]
    E --> F[结束任务]
    F --> G[领取奖励]
    G --> H[等待冷却]
    H --> I[提取质押]
```

### 观众奖励流程

```mermaid
graph LR
    A[观看直播] --> B[获取验证码]
    B --> C[提交验证]
    C --> D[获得积分]
    D --> E[积分累积]
    E --> F[兑换代币]
```

## 技术特性

### 智能合约

- ✅ 使用 OpenZeppelin 标准库
- ✅ ReentrancyGuard 防重入攻击
- ✅ Ownable 权限控制
- ✅ SafeERC20 安全代币转账
- ✅ 完整的事件日志
- ✅ 单元测试覆盖

### 前端集成

- ✅ Wagmi v2 + Viem 集成
- ✅ 实时合约状态读取
- ✅ 交易状态跟踪
- ✅ 响应式 UI 设计
- ✅ 错误处理和加载状态
- ✅ TypeScript 类型安全

## 关键参数

| 参数 | 值 | 合约 |
|------|-----|------|
| 最低质押金额 | 1000 ATT | StreamerStakingPool |
| 最短直播时长 | 300 秒 (5分钟) | StreamerStakingPool |
| 最长直播时长 | 86400 秒 (24小时) | StreamerStakingPool |
| 奖励率范围 | 100-5000 基点 (1%-50%) | StreamerStakingPool |
| 平台手续费 | 500 基点 (5%) | StreamerStakingPool |
| 提取冷却期 | 7 天 | StreamerStakingPool |
| 积分兑换率 | 1000:1 | ViewerRewardPool |
| 最低兑换积分 | 1000 | ViewerRewardPool |
| 兑换冷却期 | 1 小时 | ViewerRewardPool |

## 奖励机制

### 主播奖励计算

```solidity
基础奖励 = (质押金额 × 奖励率) / 10000
参与度倍数 = 总观众数 / 100
总奖励 = 基础奖励 × 参与度倍数
最大奖励 = 质押金额 × 50%
实际奖励 = min(总奖励, 最大奖励)
净奖励 = 实际奖励 × (1 - 平台手续费率)
```

**示例计算：**
- 质押：10,000 ATT
- 奖励率：5% (500 基点)
- 观众数：200 人

```
基础奖励 = 10,000 × 500 / 10000 = 500 ATT
参与度倍数 = 200 / 100 = 2
总奖励 = 500 × 2 = 1,000 ATT
最大奖励 = 10,000 × 50% = 5,000 ATT
实际奖励 = 1,000 ATT (未超过上限)
平台手续费 = 1,000 × 5% = 50 ATT
净奖励 = 950 ATT
```

### 观众积分系统

- 每次验证成功获得固定积分（后端配置）
- 1000 积分 = 1 ATT
- 最低兑换 1000 积分
- 1小时冷却期防止频繁兑换

## 安全考虑

### 合约安全

1. **重入攻击防护**
   - 所有涉及代币转账的函数使用 `nonReentrant`
   - 遵循 Checks-Effects-Interactions 模式

2. **权限控制**
   - 敏感函数使用 `onlyOwner` 修饰符
   - 主播只能操作自己的任务
   - 观众只能领取自己的奖励

3. **参数验证**
   - 所有输入参数都有范围检查
   - 地址非零检查
   - 金额非零检查

4. **状态管理**
   - 明确的任务状态机
   - 状态转换验证
   - 时间锁机制

### 前端安全

1. **钱包连接**
   - 使用 Wagmi 标准连接器
   - 支持多种钱包

2. **交易确认**
   - 显示交易参数
   - 等待交易确认
   - 错误处理

3. **数据验证**
   - 输入范围检查
   - 余额充足性检查
   - 授权状态检查

## 部署步骤

### 1. 合约部署

```bash
cd AttentionLive_contract

# 安装依赖
forge install OpenZeppelin/openzeppelin-contracts

# 编译
forge build

# 测试
forge test

# 部署到 BSC 测试网
forge script script/DeployContracts.s.sol \
  --rpc-url https://data-seed-prebsc-1-s1.binance.org:8545 \
  --broadcast \
  --verify \
  -vvvv
```

### 2. 前端配置

```typescript
// AttentionLive/lib/contracts/staking.ts
export const ATTENTION_TOKEN_ADDRESS = "0x..." as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0x..." as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x..." as `0x${string}`;
```

### 3. 测试流程

1. 获取测试网 BNB
2. 铸造 ATT 代币
3. 测试主播质押流程
4. 测试观众奖励流程

## 扩展功能建议

### 短期优化

1. **前端增强**
   - 添加任务列表筛选和排序
   - 实时数据刷新
   - 交易历史记录
   - 图表可视化

2. **合约优化**
   - 批量操作支持
   - Gas 优化
   - 紧急暂停功能

### 长期规划

1. **高级功能**
   - NFT 徽章系统
   - VIP 等级制度
   - 推荐奖励机制
   - 治理代币投票

2. **跨链支持**
   - 多链部署
   - 跨链桥接
   - 统一积分系统

3. **DeFi 集成**
   - 流动性挖矿
   - 质押衍生品
   - 借贷协议集成

## 文档资源

- [合约部署指南](./DEPLOYMENT.md)
- [前端使用指南](../AttentionLive/STAKING_GUIDE.md)
- [API 文档](./README.md)

## 技术栈

### 智能合约
- Solidity 0.8.23
- Foundry
- OpenZeppelin Contracts v5.0.1

### 前端
- Next.js 15
- React 18
- Wagmi v2
- Viem v2
- TypeScript
- TailwindCSS
- HeroUI

### 区块链
- BSC Testnet (Chain ID: 97)
- ERC20 标准
- Web3 钱包集成

## 贡献指南

欢迎提交 Issue 和 Pull Request！

## 许可证

MIT License
