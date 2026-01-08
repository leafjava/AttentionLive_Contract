# 🚀 本地测试快速开始

## 最快 3 步开始测试

### 步骤 1: 运行测试 (无需启动节点)

**Windows:**
```bash
cd AttentionLive_contract
test.bat
```

**Linux/Mac:**
```bash
cd AttentionLive_contract
chmod +x test.sh
./test.sh
```

这会：
- ✅ 检查 Foundry 安装
- ✅ 安装依赖
- ✅ 编译合约
- ✅ 运行所有测试

### 步骤 2: 启动本地节点

打开**新的终端窗口**:

```bash
anvil
```

保持这个窗口运行，你会看到 10 个测试账户和私钥。

### 步骤 3: 部署到本地节点

回到原来的终端:

**Windows:**
```bash
local-deploy.bat
```

**Linux/Mac:**
```bash
chmod +x local-deploy.sh
./local-deploy.sh
```

完成！合约已部署到本地节点。

---

## 📝 详细测试指南

### 方式 1: 使用 Forge Test (推荐新手)

最简单的方式，无需启动节点：

```bash
# 运行所有测试
forge test -vvv

# 运行完整流程测试
forge test --match-contract FullFlowTest -vvv

# 查看 gas 消耗
forge test --gas-report
```

**测试内容:**
- ✅ 创建质押任务
- ✅ 更新观众数据
- ✅ 结束任务
- ✅ 领取奖励
- ✅ 提取质押
- ✅ 观众积分兑换

### 方式 2: 使用 Anvil + Cast (真实交互)

更接近真实环境，可以用 MetaMask 连接：

#### 1. 启动 Anvil

```bash
anvil
```

记录输出的账户地址和私钥。

#### 2. 部署合约

```bash
forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

记录部署的合约地址。

#### 3. 设置环境变量

```bash
# Windows (PowerShell)
$env:ATT_TOKEN="0x5FbDB2315678afecb367f032d93F642f64180aa3"
$env:STAKING_POOL="0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
$env:REWARD_POOL="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
$env:DEPLOYER="0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266"
$env:STREAMER="0x70997970C51812dc3A010C7d01b50e0d17dc79C8"

# Linux/Mac
export ATT_TOKEN=0x5FbDB2315678afecb367f032d93F642f64180aa3
export STAKING_POOL=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export REWARD_POOL=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
export DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export STREAMER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8
```

#### 4. 测试交互

```bash
# 查询 ATT 余额
cast call $ATT_TOKEN "balanceOf(address)(uint256)" $DEPLOYER

# 转账给主播
cast send $ATT_TOKEN \
  "transfer(address,uint256)(bool)" \
  $STREAMER \
  100000000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 主播授权
cast send $ATT_TOKEN \
  "approve(address,uint256)(bool)" \
  $STAKING_POOL \
  10000000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 创建任务
cast send $STAKING_POOL \
  "createStreamingTask(uint256,uint256,uint256)(uint256)" \
  10000000000000000000000 \
  3600 \
  500 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
```

---

## 🎨 连接前端测试

### 1. 配置 MetaMask

添加本地网络：
- Network Name: `Localhost 8545`
- RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`
- Currency Symbol: `ETH`

### 2. 导入测试账户

使用 Anvil 提供的私钥导入账户。

### 3. 更新前端配置

```typescript
// AttentionLive/lib/contracts/staking.ts
export const ATTENTION_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3" as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512" as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0" as `0x${string}`;
```

### 4. 启动前端

```bash
cd AttentionLive
npm run dev
```

访问 http://localhost:3000/staking

---

## 🐛 常见问题

### Q: Foundry 命令找不到？

**A:** 安装 Foundry:
```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Q: 测试失败？

**A:** 清理并重新编译:
```bash
forge clean
forge build
forge test -vvv
```

### Q: Anvil 启动失败？

**A:** 检查端口是否被占用:
```bash
# 使用不同端口
anvil --port 8546
```

### Q: 部署失败？

**A:** 确保 Anvil 正在运行:
```bash
# 在另一个终端检查
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  http://127.0.0.1:8545
```

---

## 📚 更多资源

- **详细测试指南**: [LOCAL_TESTING.md](./LOCAL_TESTING.md)
- **部署指南**: [DEPLOYMENT.md](./DEPLOYMENT.md)
- **项目总结**: [PROJECT_SUMMARY.md](./PROJECT_SUMMARY.md)

---

## ✅ 测试检查清单

- [ ] 安装 Foundry
- [ ] 运行 `forge test`
- [ ] 启动 Anvil
- [ ] 部署合约
- [ ] 使用 Cast 交互
- [ ] 连接 MetaMask
- [ ] 测试前端

完成这些步骤后，你就可以完整测试质押功能了！🎉
