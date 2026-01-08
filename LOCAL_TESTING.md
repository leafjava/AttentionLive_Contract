# 本地测试指南

## 🎯 目标

在本地环境运行和测试 AttentionLive 质押合约，无需部署到测试网。

## 📋 前置要求

### 1. 安装 Foundry

**Windows (PowerShell):**
```powershell
# 使用 foundryup 安装
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

**验证安装:**
```bash
forge --version
cast --version
anvil --version
```

### 2. 安装依赖

```bash
cd AttentionLive_contract

# 安装 OpenZeppelin 合约库
forge install OpenZeppelin/openzeppelin-contracts --no-git

# 安装 forge-std (测试库)
forge install foundry-rs/forge-std --no-git
```

## 🧪 运行测试

### 方法 1: 运行现有测试

```bash
# 基础测试
forge test

# 详细输出
forge test -vvv

# 显示 gas 报告
forge test --gas-report

# 测试特定合约
forge test --match-contract StreamerStakingPoolTest

# 测试特定函数
forge test --match-test testCreateStreamingTask
```

### 方法 2: 启动本地节点 + 部署

#### 步骤 1: 启动 Anvil (本地以太坊节点)

打开一个新的终端窗口:

```bash
anvil
```

这会启动一个本地节点，默认在 `http://127.0.0.1:8545`，并提供 10 个测试账户，每个账户有 10000 ETH。

**记录输出信息:**
```
Available Accounts
==================
(0) 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266 (10000 ETH)
(1) 0x70997970C51812dc3A010C7d01b50e0d17dc79C8 (10000 ETH)
...

Private Keys
==================
(0) 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
(1) 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d
...
```

#### 步骤 2: 部署合约到本地节点

在另一个终端窗口:

```bash
cd AttentionLive_contract

# 使用 Anvil 的第一个账户部署
forge script script/DeployContracts.s.sol \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 \
  --broadcast
```

**记录部署的合约地址:**
```
AttentionToken deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
StreamerStakingPool deployed at: 0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
ViewerRewardPool deployed at: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
```

## 🔧 使用 Cast 进行交互测试

### 1. 查询合约状态

```bash
# 设置变量 (使用你部署的地址)
export ATT_TOKEN=0x5FbDB2315678afecb367f032d93F642f64180aa3
export STAKING_POOL=0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512
export REWARD_POOL=0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
export DEPLOYER=0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
export STREAMER=0x70997970C51812dc3A010C7d01b50e0d17dc79C8

# 查询 ATT 代币名称
cast call $ATT_TOKEN "name()(string)"

# 查询 ATT 代币符号
cast call $ATT_TOKEN "symbol()(string)"

# 查询部署者余额
cast call $ATT_TOKEN "balanceOf(address)(uint256)" $DEPLOYER

# 查询最低质押金额
cast call $STAKING_POOL "minStakeAmount()(uint256)"
```

### 2. 转账 ATT 代币给主播

```bash
# 转账 100,000 ATT 给主播账户
cast send $ATT_TOKEN \
  "transfer(address,uint256)(bool)" \
  $STREAMER \
  100000000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 验证主播余额
cast call $ATT_TOKEN "balanceOf(address)(uint256)" $STREAMER
```

### 3. 主播创建质押任务

```bash
# 步骤 1: 授权质押池使用 ATT
cast send $ATT_TOKEN \
  "approve(address,uint256)(bool)" \
  $STAKING_POOL \
  10000000000000000000000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 步骤 2: 创建质押任务
# createStreamingTask(uint256 stakedAmount, uint256 duration, uint256 rewardRate)
# 质押 10000 ATT, 时长 3600 秒 (1小时), 奖励率 500 (5%)
cast send $STAKING_POOL \
  "createStreamingTask(uint256,uint256,uint256)(uint256)" \
  10000000000000000000000 \
  3600 \
  500 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 查询任务详情 (taskId = 1)
cast call $STAKING_POOL "tasks(uint256)" 1
```

### 4. 更新观众数据 (Owner 操作)

```bash
# updateViewerData(uint256 taskId, uint256 totalViewers, uint256 totalPoints)
cast send $STAKING_POOL \
  "updateViewerData(uint256,uint256,uint256)" \
  1 \
  100 \
  5000 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
```

### 5. 快进时间 (模拟任务结束)

```bash
# 快进 3601 秒
cast rpc evm_increaseTime 3601 --rpc-url http://127.0.0.1:8545
cast rpc evm_mine --rpc-url http://127.0.0.1:8545
```

### 6. 结束任务

```bash
# endStreamingTask(uint256 taskId)
cast send $STAKING_POOL \
  "endStreamingTask(uint256)" \
  1 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 查询任务状态
cast call $STAKING_POOL "tasks(uint256)" 1
```

### 7. 领取奖励

```bash
# claimStreamerReward(uint256 taskId)
cast send $STAKING_POOL \
  "claimStreamerReward(uint256)" \
  1 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d

# 查询主播余额 (应该增加了奖励)
cast call $ATT_TOKEN "balanceOf(address)(uint256)" $STREAMER
```

### 8. 测试观众奖励

```bash
# 设置观众地址
export VIEWER=0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC

# Owner 添加积分给观众
cast send $REWARD_POOL \
  "addPoints(address,uint256,uint256)" \
  $VIEWER \
  5000 \
  1 \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80

# 查询观众账户
cast call $REWARD_POOL "getViewerAccount(address)" $VIEWER

# 查询可领取代币数量
cast call $REWARD_POOL "getClaimableTokens(address)(uint256)" $VIEWER

# 观众领取奖励
cast send $REWARD_POOL \
  "claimReward()" \
  --rpc-url http://127.0.0.1:8545 \
  --private-key 0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a

# 查询观众 ATT 余额
cast call $ATT_TOKEN "balanceOf(address)(uint256)" $VIEWER
```

## 📝 创建自定义测试脚本

创建一个完整的测试脚本 `test/FullFlow.t.sol`:

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import {AttentionToken} from "../src/AttentionToken.sol";
import {StreamerStakingPool} from "../src/StreamerStakingPool.sol";
import {ViewerRewardPool} from "../src/ViewerRewardPool.sol";

contract FullFlowTest is Test {
    AttentionToken public attToken;
    StreamerStakingPool public stakingPool;
    ViewerRewardPool public rewardPool;
    
    address public owner = address(1);
    address public streamer = address(2);
    address public viewer = address(3);
    address public feeCollector = address(4);
    
    function setUp() public {
        vm.startPrank(owner);
        
        // 部署合约
        attToken = new AttentionToken();
        stakingPool = new StreamerStakingPool(attToken, feeCollector);
        rewardPool = new ViewerRewardPool(attToken);
        
        // 转账代币
        attToken.transfer(streamer, 100_000 * 10**18);
        attToken.transfer(address(rewardPool), 10_000_000 * 10**18);
        attToken.transfer(address(stakingPool), 5_000_000 * 10**18);
        
        vm.stopPrank();
        
        console.log("Setup complete!");
        console.log("ATT Token:", address(attToken));
        console.log("Staking Pool:", address(stakingPool));
        console.log("Reward Pool:", address(rewardPool));
    }
    
    function testFullFlow() public {
        console.log("\n=== Starting Full Flow Test ===\n");
        
        // 1. 主播创建任务
        console.log("1. Streamer creates task...");
        vm.startPrank(streamer);
        
        uint256 stakeAmount = 10_000 * 10**18;
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, 3600, 500);
        
        console.log("Task created with ID:", taskId);
        vm.stopPrank();
        
        // 2. 更新观众数据
        console.log("\n2. Updating viewer data...");
        vm.prank(owner);
        stakingPool.updateViewerData(taskId, 100, 5000);
        console.log("Viewer data updated: 100 viewers, 5000 points");
        
        // 3. 快进时间
        console.log("\n3. Fast forwarding time...");
        vm.warp(block.timestamp + 3601);
        console.log("Time advanced by 3601 seconds");
        
        // 4. 结束任务
        console.log("\n4. Ending task...");
        vm.prank(streamer);
        stakingPool.endStreamingTask(taskId);
        console.log("Task ended");
        
        // 5. 领取奖励
        console.log("\n5. Claiming reward...");
        uint256 balanceBefore = attToken.balanceOf(streamer);
        vm.prank(streamer);
        stakingPool.claimStreamerReward(taskId);
        uint256 balanceAfter = attToken.balanceOf(streamer);
        
        console.log("Balance before:", balanceBefore / 10**18, "ATT");
        console.log("Balance after:", balanceAfter / 10**18, "ATT");
        console.log("Reward received:", (balanceAfter - balanceBefore) / 10**18, "ATT");
        
        // 6. 观众获得积分
        console.log("\n6. Adding points to viewer...");
        vm.prank(owner);
        rewardPool.addPoints(viewer, 5000, taskId);
        console.log("5000 points added to viewer");
        
        // 7. 观众兑换奖励
        console.log("\n7. Viewer claiming reward...");
        uint256 viewerBalanceBefore = attToken.balanceOf(viewer);
        vm.prank(viewer);
        rewardPool.claimReward();
        uint256 viewerBalanceAfter = attToken.balanceOf(viewer);
        
        console.log("Viewer balance before:", viewerBalanceBefore / 10**18, "ATT");
        console.log("Viewer balance after:", viewerBalanceAfter / 10**18, "ATT");
        console.log("Reward received:", (viewerBalanceAfter - viewerBalanceBefore) / 10**18, "ATT");
        
        console.log("\n=== Full Flow Test Complete! ===\n");
    }
}
```

运行这个测试:

```bash
forge test --match-contract FullFlowTest -vvv
```

## 🎨 前端本地测试

### 1. 配置前端连接本地节点

```typescript
// AttentionLive/config/wagmi.ts
import { http, createConfig } from 'wagmi'
import { localhost } from 'wagmi/chains'

export const config = createConfig({
  chains: [localhost],
  transports: {
    [localhost.id]: http('http://127.0.0.1:8545'),
  },
})
```

### 2. 更新合约地址

```typescript
// AttentionLive/lib/contracts/staking.ts
export const ATTENTION_TOKEN_ADDRESS = "0x5FbDB2315678afecb367f032d93F642f64180aa3" as `0x${string}`;
export const STREAMER_STAKING_POOL_ADDRESS = "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512" as `0x${string}`;
export const VIEWER_REWARD_POOL_ADDRESS = "0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0" as `0x${string}`;
```

### 3. 在 MetaMask 中添加本地网络

- Network Name: Localhost 8545
- RPC URL: http://127.0.0.1:8545
- Chain ID: 31337
- Currency Symbol: ETH

### 4. 导入测试账户

使用 Anvil 提供的私钥导入账户到 MetaMask。

### 5. 启动前端

```bash
cd AttentionLive
npm run dev
```

访问 http://localhost:3000/staking

## 📊 常用命令速查

```bash
# 编译合约
forge build

# 运行测试
forge test -vvv

# 启动本地节点
anvil

# 部署到本地
forge script script/DeployContracts.s.sol --rpc-url http://127.0.0.1:8545 --broadcast

# 查询合约
cast call <CONTRACT> "functionName()(returnType)"

# 发送交易
cast send <CONTRACT> "functionName(params)" <args> --private-key <KEY>

# 快进时间
cast rpc evm_increaseTime <seconds>
cast rpc evm_mine

# 查看区块
cast block-number

# 查看余额
cast balance <ADDRESS>
```

## 🐛 故障排除

### 问题 1: Foundry 命令未找到

**解决方案:**
```bash
# 重新安装 Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### 问题 2: 依赖安装失败

**解决方案:**
```bash
# 清理并重新安装
rm -rf lib
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge install foundry-rs/forge-std --no-commit
```

### 问题 3: 测试失败

**解决方案:**
```bash
# 清理缓存
forge clean
forge build
forge test -vvv
```

### 问题 4: Anvil 端口被占用

**解决方案:**
```bash
# 使用不同端口
anvil --port 8546

# 更新 RPC URL
--rpc-url http://127.0.0.1:8546
```

## 🎯 下一步

1. ✅ 运行基础测试
2. ✅ 启动本地节点
3. ✅ 部署合约
4. ✅ 使用 Cast 交互
5. ✅ 运行完整流程测试
6. ✅ 连接前端测试

祝测试顺利！🚀
