# Sepolia 测试网部署记录

## 📅 部署信息

- **部署时间**: 2024 年（根据区块 10001642）
- **网络**: Sepolia Testnet
- **链 ID**: 11155111
- **部署者地址**: `0xEd32E959FE97d5c1D3f1248CdfF6142D619fB956`

---

## 📝 合约地址

### AttentionToken (ATT)
- **地址**: `0xdad467714C3f47A80463f6CfcAc16739dDa0883b`
- **Etherscan**: https://sepolia.etherscan.io/address/0xdad467714C3f47A80463f6CfcAc16739dDa0883b
- **验证状态**: ✅ 已验证

### StreamerStakingPool
- **地址**: `0x3ee9A32c2f6e6C856Ffa070c2963C2Ac7e559023`
- **Etherscan**: https://sepolia.etherscan.io/address/0x3ee9A32c2f6e6C856Ffa070c2963C2Ac7e559023
- **验证状态**: ✅ 已验证

### ViewerRewardPool
- **地址**: `0xbd4809912624f5D5571eeB11d1a8F699C06A5f83`
- **Etherscan**: https://sepolia.etherscan.io/address/0xbd4809912624f5D5571eeB11d1a8F699C06A5f83
- **验证状态**: ✅ 已验证

---

## 💰 代币分配

| 地址 | ATT 数量 | 百分比 |
|------|----------|--------|
| 部署者 (0xEd32...B956) | 85,000,000 ATT | 85% |
| ViewerRewardPool | 10,000,000 ATT | 10% |
| StreamerStakingPool | 5,000,000 ATT | 5% |
| **总计** | **100,000,000 ATT** | **100%** |

---

## ⛽ Gas 费用

| 操作 | Gas 使用 | 费用 (ETH) |
|------|----------|-----------|
| AttentionToken | 1,282,792 | 0.001282806110712 |
| StreamerStakingPool | 2,461,273 | 0.002461300074003 |
| ViewerRewardPool | 1,746,300 | 0.0017463192093 |
| 转账 (Reward Pool) | 52,172 | 0.000052172573892 |
| 转账 (Staking Pool) | 52,184 | 0.000052184574024 |
| **总计** | **5,594,721** | **0.005594782541931** |

**平均 Gas 价格**: 0.001000011 gwei

---

## 🔗 交易哈希

1. **AttentionToken 部署**
   - Hash: `0x8aacba2dd6e3418211dd199a78b85ba226330b0f07075e4bcc21b8324339f1592`
   - Block: 10001642

2. **StreamerStakingPool 部署**
   - Hash: `0x60edb1747362591f75cc807520c9eb4b86793450014e451f8f183c0fa141`
   - Block: 10001642

3. **ViewerRewardPool 部署**
   - Hash: `0x55bade3a47091315621554fd5bdc56a6e87211f514d00377de8e6e2432a2c113`
   - Block: 10001642

4. **ViewerRewardPool 充值**
   - Hash: `0x5b2e44493535a60dad2fd39284f1bb0a547673cf722cac50e9b868f897c6a456`
   - Block: 10001642

5. **StreamerStakingPool 充值**
   - Hash: `0x992eb2be2d8ad30414a0068e6cb9da784fc311f7f5f256befd2139bbaf89b751`
   - Block: 10001642

---

## 📱 MetaMask 配置

### 添加 ATT 代币

**代币地址**: `0xdad467714C3f47A80463f6CfcAc16739dDa0883b`
**代币符号**: ATT
**小数位数**: 18

### 添加到 MetaMask 的链接

点击此链接自动添加（需要在 MetaMask 浏览器中打开）：
```
https://sepolia.etherscan.io/token/0xdad467714C3f47A80463f6CfcAc16739dDa0883b
```

---

## 🔧 前端配置

### 更新 staking.ts

编辑 `AttentionLive/lib/contracts/staking.ts`：

```typescript
// Sepolia Testnet (chainId 11155111)
export const ATTENTION_TOKEN_ADDRESS = "0xdad467714C3f47A80463f6CfcAc16739dDa0883b" as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0x3ee9A32c2f6e6C856Ffa070c2963C2Ac7e559023" as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0xbd4809912624f5D5571eeB11d1a8F699C06A5f83" as `0x${string}`;
```

### 更新 wagmi.ts

确保包含 Sepolia 网络：

```typescript
import { sepolia } from 'wagmi/chains';

export const config = createConfig({
  chains: [sepolia],
  // ...
});
```

---

## ✅ 验证清单

- [x] 合约已成功部署
- [x] 合约已在 Etherscan 上验证
- [x] ViewerRewardPool 已充值 10M ATT
- [x] StreamerStakingPool 已充值 5M ATT
- [ ] 前端配置已更新
- [ ] MetaMask 已添加 ATT 代币
- [ ] 完整流程测试通过

---

## 🧪 测试步骤

### 1. 添加 ATT 到 MetaMask

1. 打开 MetaMask
2. 切换到 Sepolia 网络
3. 点击"导入代币"
4. 输入地址: `0xdad467714C3f47A80463f6CfcAc16739dDa0883b`
5. 确认添加

### 2. 获取测试 ATT

从部署者地址转一些 ATT 到你的测试账户：

```bash
cast send 0xdad467714C3f47A80463f6CfcAc16739dDa0883b \
  "transfer(address,uint256)" \
  <你的地址> \
  1000000000000000000000 \
  --rpc-url https://sepolia.infura.io/v3/726930ebd0e248ff94a8da1ce85ee33a \
  --private-key 0x5401ea437737a889cd2771424203a680e298ae60ac70862b98267fc569b62884
```

### 3. 测试质押流程

1. 访问前端: http://localhost:3000/staking
2. 连接 MetaMask (Sepolia)
3. Approve ATT
4. Create Task (1000 ATT, 10 秒)
5. 等待 10 秒
6. End Task
7. Claim Reward
8. 等待 10 秒
9. Unstake

---

## 📊 合约配置

### StreamerStakingPool

- 最低质押: 1000 ATT
- 冷却期: 10 秒（测试配置）
- 平台手续费: 5% (500 基点)
- 最短任务时间: 10 秒
- 最长任务时间: 24 小时

### ViewerRewardPool

- 兑换率: 1000 积分 = 1 ATT
- 最低兑换: 1000 积分
- 兑换冷却: 1 小时

---

## 🔒 安全提醒

- ⚠️ 这是测试网部署，代币没有实际价值
- ⚠️ 不要在主网使用相同的私钥
- ⚠️ 定期备份合约地址和配置
- ⚠️ 测试配置（10秒）不适合生产环境

---

## 📞 联系方式

如有问题，请查看：
- `DEPLOY_TO_SEPOLIA.md` - 部署指南
- `POST_DEPLOY_SETUP.md` - 配置指南
- `DEPLOYMENT_SUMMARY.md` - 部署总览

---

**部署成功！🎉**

所有合约已部署并验证，可以开始测试了！
