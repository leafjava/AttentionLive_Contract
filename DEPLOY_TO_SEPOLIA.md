# 部署到 Sepolia 测试网指南

## 📋 前置准备

### 1. 获取 Sepolia ETH 测试币

你需要一些 Sepolia ETH 来支付 gas 费用。

**方式 1: Alchemy Faucet（推荐）**
- 访问：https://sepoliafaucet.com/
- 登录 Alchemy 账号
- 输入你的钱包地址
- 每天可领取 0.5 SepoliaETH

**方式 2: Infura Faucet**
- 访问：https://www.infura.io/faucet/sepolia
- 需要 Infura 账号

**方式 3: QuickNode Faucet**
- 访问：https://faucet.quicknode.com/ethereum/sepolia
- 需要 Discord 账号验证

**方式 4: Chainlink Faucet**
- 访问：https://faucets.chain.link/sepolia
- 需要 0.001 ETH 主网余额或 GitHub 账号

### 2. 获取 RPC URL

**选项 A: Alchemy（推荐）**
1. 访问 https://www.alchemy.com/
2. 注册并创建新应用
3. 选择 Ethereum → Sepolia
4. 复制 HTTPS URL，格式如：
   ```
   https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY
   ```

**选项 B: Infura**
1. 访问 https://www.infura.io/
2. 创建项目
3. 选择 Sepolia 网络
4. 复制 HTTPS endpoint

**选项 C: 公共 RPC（免费但可能不稳定）**
```
https://rpc.sepolia.org
https://ethereum-sepolia.publicnode.com
https://1rpc.io/sepolia
```

### 3. 获取 Etherscan API Key（用于合约验证）

1. 访问 https://etherscan.io/
2. 注册账号
3. 进入 API Keys 页面：https://etherscan.io/myapikey
4. 创建新的 API Key
5. 复制 API Key

---

## 🔧 配置步骤

### 步骤 1: 创建 .env 文件

在 `AttentionLive_contract` 目录下创建 `.env` 文件：

```bash
cd AttentionLive_contract
copy .env.example .env  # Windows
# 或
cp .env.example .env    # Mac/Linux
```

### 步骤 2: 编辑 .env 文件

打开 `.env` 文件，填入以下信息：

```bash
# 你的钱包私钥（不要包含 0x 前缀）
# ⚠️ 警告：不要泄露私钥！不要提交到 Git！
PRIVATE_KEY=你的私钥（64位十六进制字符）

# Sepolia RPC URL
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_API_KEY

# Etherscan API Key（用于合约验证）
ETHERSCAN_API_KEY=你的Etherscan_API_Key
```

**如何获取私钥？**

**MetaMask:**
1. 打开 MetaMask
2. 点击右上角三个点 → 账户详情
3. 点击"导出私钥"
4. 输入密码
5. 复制私钥（去掉 0x 前缀）

**⚠️ 安全提醒：**
- 不要使用存有真实资金的钱包
- 建议创建一个专门用于测试的新钱包
- 永远不要将 `.env` 文件提交到 Git
- `.gitignore` 已包含 `.env`，确保不会被提交

### 步骤 3: 更新 foundry.toml

编辑 `foundry.toml`，添加 Sepolia 配置：

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
solc_version = "0.8.23"

[rpc_endpoints]
sepolia = "${SEPOLIA_RPC_URL}"
bsc_testnet = "https://data-seed-prebsc-1-s1.binance.org:8545"

[etherscan]
sepolia = { key = "${ETHERSCAN_API_KEY}" }
bsc_testnet = { key = "${BSCSCAN_API_KEY}", url = "https://api-testnet.bscscan.com/api" }
```

---

## 🚀 部署合约

### 方式 1: 使用部署脚本（推荐）

```bash
cd AttentionLive_contract

# 部署到 Sepolia
forge script script/DeployContracts.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv
```

**参数说明：**
- `--rpc-url sepolia`: 使用 Sepolia 网络
- `--broadcast`: 实际发送交易到链上
- `--verify`: 自动验证合约源码
- `-vvvv`: 显示详细日志

### 方式 2: 使用环境变量

```bash
forge script script/DeployContracts.s.sol \
  --rpc-url $SEPOLIA_RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  -vvvv
```

### 方式 3: 分步部署（更安全）

**步骤 1: 模拟部署（不发送交易）**
```bash
forge script script/DeployContracts.s.sol \
  --rpc-url sepolia \
  -vvvv
```

检查输出，确认一切正常。

**步骤 2: 实际部署**
```bash
forge script script/DeployContracts.s.sol \
  --rpc-url sepolia \
  --broadcast \
  -vvvv
```

**步骤 3: 验证合约**
```bash
# 验证 AttentionToken
forge verify-contract \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  <合约地址> \
  src/AttentionToken.sol:AttentionToken

# 验证 StreamerStakingPool
forge verify-contract \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address,address)" <ATT地址> <手续费收集地址>) \
  <合约地址> \
  src/StreamerStakingPool.sol:StreamerStakingPool

# 验证 ViewerRewardPool
forge verify-contract \
  --chain-id 11155111 \
  --etherscan-api-key $ETHERSCAN_API_KEY \
  --constructor-args $(cast abi-encode "constructor(address)" <ATT地址>) \
  <合约地址> \
  src/ViewerRewardPool.sol:ViewerRewardPool
```

---

## 📝 部署后的操作

### 1. 记录合约地址

部署成功后，你会看到类似输出：

```
=== Deployment Summary ===
AttentionToken: 0x1234...
StreamerStakingPool: 0x5678...
ViewerRewardPool: 0x9abc...
Deployer: 0xdef0...
```

**保存这些地址！**

### 2. 更新前端配置

编辑 `AttentionLive/lib/contracts/staking.ts`：

```typescript
// Sepolia Testnet (chainId 11155111)
export const ATTENTION_TOKEN_ADDRESS = "0x你的ATT合约地址" as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0x你的质押池地址" as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x你的奖励池地址" as `0x${string}`;
```

### 3. 更新前端网络配置

编辑 `AttentionLive/config/wagmi.ts`，确保包含 Sepolia：

```typescript
import { sepolia } from 'wagmi/chains';

export const config = createConfig({
  chains: [sepolia], // 或 [localhost, sepolia]
  // ...
});
```

### 4. 在 Etherscan 上查看

访问 Sepolia Etherscan：
- AttentionToken: `https://sepolia.etherscan.io/address/你的ATT地址`
- StreamerStakingPool: `https://sepolia.etherscan.io/address/你的质押池地址`
- ViewerRewardPool: `https://sepolia.etherscan.io/address/你的奖励池地址`

---

## 🧪 测试部署

### 1. 在 MetaMask 中添加 Sepolia 网络

1. 打开 MetaMask
2. 点击网络下拉菜单
3. 点击"添加网络"
4. 选择"Sepolia 测试网络"

**手动添加（如果没有）：**
- 网络名称: Sepolia
- RPC URL: https://rpc.sepolia.org
- 链 ID: 11155111
- 货币符号: ETH
- 区块浏览器: https://sepolia.etherscan.io

### 2. 添加 ATT 代币到 MetaMask

1. 在 MetaMask 中点击"导入代币"
2. 选择"自定义代币"
3. 输入 ATT 合约地址
4. 代币符号会自动填充为 ATT
5. 点击"添加"

### 3. 测试前端连接

```bash
cd AttentionLive
pnpm dev
```

访问 http://localhost:3000/staking，连接 MetaMask（Sepolia 网络），测试功能。

---

## ⚠️ 常见问题

### Q1: 部署失败：insufficient funds

**原因**: 钱包余额不足

**解决**:
1. 检查钱包地址：`cast wallet address --private-key $PRIVATE_KEY`
2. 检查余额：`cast balance <你的地址> --rpc-url sepolia`
3. 从水龙头获取更多 SepoliaETH

### Q2: 部署失败：nonce too low

**原因**: Nonce 冲突

**解决**:
```bash
# 清除本地缓存
rm -rf cache/ out/
forge clean
# 重新部署
```

### Q3: 合约验证失败

**原因**: 可能是编译器版本不匹配或构造函数参数错误

**解决**:
1. 确认 `foundry.toml` 中的 `solc_version = "0.8.23"`
2. 等待几分钟后重试
3. 手动在 Etherscan 上验证

### Q4: RPC 请求失败

**原因**: RPC URL 无效或达到速率限制

**解决**:
1. 检查 `.env` 中的 `SEPOLIA_RPC_URL`
2. 尝试使用其他 RPC 提供商
3. 如果使用 Alchemy/Infura，检查 API Key 是否正确

### Q5: 私钥格式错误

**原因**: 私钥包含 0x 前缀或格式不正确

**解决**:
- 确保私钥是 64 位十六进制字符（不含 0x）
- 示例：`ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80`

---

## 📊 Gas 费用估算

Sepolia 部署大约需要的 Gas：

| 操作 | 估算 Gas | 估算费用（10 Gwei） |
|------|----------|---------------------|
| AttentionToken | ~1,500,000 | ~0.015 ETH |
| StreamerStakingPool | ~2,500,000 | ~0.025 ETH |
| ViewerRewardPool | ~2,000,000 | ~0.020 ETH |
| 代币转账（资金池） | ~100,000 | ~0.001 ETH |
| **总计** | ~6,100,000 | **~0.061 ETH** |

**建议准备 0.1 SepoliaETH 以确保足够。**

---

## 🔒 安全检查清单

部署前请确认：

- [ ] 使用的是测试钱包（不含真实资金）
- [ ] `.env` 文件已添加到 `.gitignore`
- [ ] 私钥从未分享或提交到代码库
- [ ] 已在 Sepolia 获取足够的测试 ETH
- [ ] RPC URL 和 API Key 正确配置
- [ ] 合约代码已经过测试（`forge test`）
- [ ] 了解部署后无法修改合约代码

---

## 📚 相关资源

- [Sepolia Testnet 信息](https://sepolia.dev/)
- [Sepolia Etherscan](https://sepolia.etherscan.io/)
- [Foundry Book - 部署指南](https://book.getfoundry.sh/forge/deploying)
- [Alchemy 文档](https://docs.alchemy.com/)
- [Etherscan 验证指南](https://docs.etherscan.io/tutorials/verifying-contracts-programmatically)

---

## 🎯 快速部署命令总结

```bash
# 1. 进入合约目录
cd AttentionLive_contract

# 2. 创建并配置 .env 文件
copy .env.example .env
# 编辑 .env，填入私钥、RPC URL、API Key

# 3. 测试编译
forge build

# 4. 运行测试
forge test

# 5. 模拟部署（检查）
forge script script/DeployContracts.s.sol --rpc-url sepolia -vvvv

# 6. 实际部署并验证
forge script script/DeployContracts.s.sol \
  --rpc-url sepolia \
  --broadcast \
  --verify \
  -vvvv

# 7. 记录合约地址并更新前端配置
```

---

## ✨ 部署成功后

恭喜！你的合约已成功部署到 Sepolia 测试网。

**下一步：**
1. ✅ 在 Etherscan 上查看合约
2. ✅ 更新前端配置文件
3. ✅ 在 MetaMask 中添加 ATT 代币
4. ✅ 测试完整的质押流程
5. ✅ 分享合约地址给团队成员

**注意事项：**
- Sepolia 是测试网，代币没有实际价值
- 定期备份合约地址和部署信息
- 如需重新部署，记得更新前端配置

祝部署顺利！🎉
