# 部署指南总览

## 📚 文档索引

本项目提供了完整的部署文档，请按需查阅：

### 1. 本地测试部署
- **文件**: `LOCAL_TESTING.md`
- **用途**: 在本地 Anvil 节点上测试合约
- **适合**: 开发和快速测试

### 2. Sepolia 测试网部署 ⭐
- **文件**: `DEPLOY_TO_SEPOLIA.md`
- **用途**: 部署到 Sepolia 公共测试网
- **适合**: 团队协作测试、演示

### 3. 部署后配置
- **文件**: `POST_DEPLOY_SETUP.md`
- **用途**: 部署成功后的配置和测试
- **适合**: 部署完成后的必读文档

### 4. 快速重新部署
- **文件**: `QUICK_REDEPLOY.md`
- **用途**: 快速重新部署（10秒测试配置）
- **适合**: 频繁测试和迭代

---

## 🚀 快速开始

### 本地测试（最快）

```bash
# 1. 启动本地节点
cd AttentionLive_contract
anvil

# 2. 部署合约（新终端）
forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast

# 3. 启动前端
cd ../AttentionLive
pnpm dev
```

**耗时**: 约 2 分钟

---

### Sepolia 测试网（推荐）

```bash
# 1. 配置环境
cd AttentionLive_contract
copy .env.example .env
# 编辑 .env，填入私钥和 RPC URL

# 2. 获取测试币
# 访问 https://sepoliafaucet.com/

# 3. 部署（Windows）
deploy-sepolia.bat

# 或部署（Mac/Linux）
./deploy-sepolia.sh

# 4. 更新前端配置
# 编辑 AttentionLive/lib/contracts/staking.ts

# 5. 启动前端
cd ../AttentionLive
pnpm dev
```

**耗时**: 约 10-15 分钟（包括获取测试币）

---

## 📋 部署前检查清单

### 本地部署
- [ ] 安装了 Foundry (`forge --version`)
- [ ] 安装了 Node.js 和 pnpm
- [ ] 克隆了项目代码
- [ ] 安装了依赖 (`forge install`, `pnpm install`)

### Sepolia 部署
- [ ] 创建了测试钱包
- [ ] 获取了 Sepolia ETH（至少 0.1 ETH）
- [ ] 获取了 RPC URL（Alchemy/Infura）
- [ ] 获取了 Etherscan API Key
- [ ] 配置了 .env 文件
- [ ] 测试通过 (`forge test`)

---

## 🔧 配置文件说明

### 合约配置

**foundry.toml** - Foundry 配置
```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.23"

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
```

**.env** - 环境变量（不要提交到 Git）
```bash
PRIVATE_KEY=你的私钥
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
ETHERSCAN_API_KEY=你的API_Key
```

### 前端配置

**staking.ts** - 合约地址配置
```typescript
export const ATTENTION_TOKEN_ADDRESS = "0x..." as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0x..." as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x..." as `0x${string}`;
```

**wagmi.ts** - 网络配置
```typescript
import { sepolia } from 'wagmi/chains';

export const config = createConfig({
  chains: [sepolia],
  // ...
});
```

---

## 🎯 部署流程对比

| 特性 | 本地 Anvil | Sepolia 测试网 |
|------|-----------|---------------|
| **速度** | ⚡ 极快（秒级） | 🐢 较慢（分钟级） |
| **成本** | 💰 免费 | 💰 免费（需测试币） |
| **持久性** | ❌ 重启丢失 | ✅ 永久保存 |
| **团队协作** | ❌ 仅本地 | ✅ 可共享 |
| **区块浏览器** | ❌ 无 | ✅ Etherscan |
| **时间控制** | ✅ 可快进 | ❌ 真实时间 |
| **适用场景** | 开发测试 | 演示、集成测试 |

---

## 📊 合约信息

### 合约列表

1. **AttentionToken (ATT)**
   - 类型: ERC20 代币
   - 初始供应: 100,000,000 ATT
   - 小数位数: 18
   - 功能: 铸造、销毁

2. **StreamerStakingPool**
   - 类型: 质押池
   - 功能: 主播质押、奖励计算
   - 最低质押: 1000 ATT
   - 冷却期: 10 秒（测试）/ 7 天（生产）

3. **ViewerRewardPool**
   - 类型: 奖励池
   - 功能: 观众积分、代币兑换
   - 兑换率: 1000 积分 = 1 ATT
   - 冷却期: 1 小时

### 初始资金分配

部署后的代币分配：

| 地址 | 数量 | 百分比 |
|------|------|--------|
| 部署者 | 85,000,000 ATT | 85% |
| ViewerRewardPool | 10,000,000 ATT | 10% |
| StreamerStakingPool | 5,000,000 ATT | 5% |
| **总计** | **100,000,000 ATT** | **100%** |

---

## 🛠️ 常用命令

### 合约开发

```bash
# 编译合约
forge build

# 运行测试
forge test

# 运行测试（详细输出）
forge test -vvvv

# 检查 gas 使用
forge test --gas-report

# 格式化代码
forge fmt

# 清理缓存
forge clean
```

### 部署相关

```bash
# 本地部署
forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key <私钥> \
  --broadcast

# Sepolia 部署
forge script script/DeployContracts.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify

# 验证合约
forge verify-contract \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  <合约地址> \
  <合约路径>
```

### 查询命令

```bash
# 查看钱包地址
cast wallet address --private-key $PRIVATE_KEY

# 查看余额
cast balance <地址> --rpc-url sepolia

# 查看代币余额
cast call <ATT地址> "balanceOf(address)(uint256)" <地址> --rpc-url sepolia

# 发送交易
cast send <合约地址> "函数签名" <参数> --rpc-url sepolia --private-key $PRIVATE_KEY
```

---

## 🔗 有用的链接

### 开发工具
- [Foundry Book](https://book.getfoundry.sh/)
- [Solidity 文档](https://docs.soliditylang.org/)
- [OpenZeppelin 合约](https://docs.openzeppelin.com/contracts/)

### Sepolia 测试网
- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Sepolia Faucet (Alchemy)](https://sepoliafaucet.com/)
- [Sepolia Faucet (Infura)](https://www.infura.io/faucet/sepolia)
- [Chainlink Faucet](https://faucets.chain.link/sepolia)

### RPC 提供商
- [Alchemy](https://www.alchemy.com/)
- [Infura](https://www.infura.io/)
- [QuickNode](https://www.quicknode.com/)

### 前端开发
- [Wagmi 文档](https://wagmi.sh/)
- [Viem 文档](https://viem.sh/)
- [Next.js 文档](https://nextjs.org/docs)

---

## 🆘 获取帮助

### 常见问题

查看以下文档的"常见问题"部分：
- `DEPLOY_TO_SEPOLIA.md` - Sepolia 部署问题
- `LOCAL_TESTING.md` - 本地测试问题
- `POST_DEPLOY_SETUP.md` - 配置问题

### 调试技巧

1. **查看详细日志**: 使用 `-vvvv` 参数
2. **检查 gas 费用**: 确保钱包有足够余额
3. **验证配置**: 检查 .env 和 foundry.toml
4. **清理缓存**: 运行 `forge clean`
5. **查看区块浏览器**: 在 Etherscan 上查看交易详情

---

## 📝 下一步

部署成功后：

1. ✅ 阅读 `POST_DEPLOY_SETUP.md`
2. ✅ 更新前端配置
3. ✅ 测试完整流程
4. ✅ 邀请团队成员测试
5. ✅ 收集反馈并改进
6. ✅ 考虑安全审计（主网前）

---

## 🎉 总结

本项目提供了完整的部署文档和工具：

- 📖 详细的步骤说明
- 🛠️ 自动化部署脚本
- ✅ 部署后检查清单
- 🐛 常见问题解答
- 🔗 有用的资源链接

选择适合你的部署方式，开始使用 AttentionLive！

祝部署顺利！🚀
