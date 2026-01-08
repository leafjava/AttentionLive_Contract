// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// 导入 OpenZeppelin 的 ERC20 接口
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 导入 OpenZeppelin 的安全 ERC20 操作库（防止转账失败）
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// 导入 OpenZeppelin 的所有权管理合约
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// 导入 OpenZeppelin 的重入攻击防护合约
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title StreamerStakingPool（主播质押池）
/// @notice 主播质押 ATT 代币创建直播任务，根据观众参与度获得奖励
/// @dev 继承 Ownable（所有权管理）和 ReentrancyGuard（防重入攻击）
contract StreamerStakingPool is Ownable, ReentrancyGuard {
    // 使用 SafeERC20 库来安全地操作 ERC20 代币
    using SafeERC20 for IERC20;

    // ============ 枚举类型 ============
    
    /// @notice 任务状态枚举
    enum TaskStatus {
        Active,      // 0: 直播进行中
        Ended,       // 1: 直播已结束，可领取奖励
        Claimed,     // 2: 奖励已领取，等待冷却期
        Unstaked     // 3: 质押已取回
    }

    // ============ 数据结构 ============
    
    /// @notice 直播任务结构体
    /// @dev 存储单个直播任务的所有信息
    struct StreamingTask {
        address streamer;           // 主播地址
        uint256 stakedAmount;       // 质押的 ATT 数量（wei 单位）
        uint256 startTime;          // 任务开始时间戳（秒）
        uint256 endTime;            // 任务结束时间戳（秒）
        uint256 duration;           // 直播持续时间（秒）
        uint256 rewardRate;         // 奖励率（基点，100 = 1%）
        uint256 totalViewers;       // 验证的观众总数
        uint256 totalPoints;        // 分发给观众的总积分
        uint256 streamerReward;     // 计算出的主播奖励（wei 单位）
        TaskStatus status;          // 当前任务状态
        uint256 unstakeTime;        // 可以取回质押的时间戳（0 表示未设置）
    }

    // ============ 状态变量 ============
    
    /// @notice ATT 代币合约地址（不可变）
    /// @dev immutable 表示部署后不可更改，节省 gas
    IERC20 public immutable attToken;
    
    /// @notice 最低质押金额（1000 ATT）
    /// @dev 10**18 是因为 ATT 使用 18 位小数
    uint256 public minStakeAmount = 1000 * 10**18;
    
    /// @notice 取回质押的冷却期（10 秒，用于测试）
    /// @dev 生产环境应设置为 7 天
    uint256 public unstakeCooldown = 10; // 10 秒
    
    /// @notice 平台手续费率（5% = 500 基点）
    /// @dev 基点（basis points）：10000 基点 = 100%，500 基点 = 5%
    uint256 public platformFeeRate = 500;
    
    /// @notice 平台手续费收集地址
    address public feeCollector;

    /// @notice 任务 ID 到任务详情的映射
    mapping(uint256 => StreamingTask) public tasks;
    
    /// @notice 主播地址到其所有任务 ID 列表的映射
    mapping(address => uint256[]) public streamerTasks;
    
    /// @notice 下一个任务 ID（从 1 开始递增）
    uint256 public nextTaskId = 1;

    // ============ 事件 ============
    
    /// @notice 任务创建事件
    /// @param taskId 任务 ID
    /// @param streamer 主播地址
    /// @param stakedAmount 质押金额
    /// @param duration 持续时间
    /// @param rewardRate 奖励率
    event TaskCreated(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 stakedAmount,
        uint256 duration,
        uint256 rewardRate
    );
    
    /// @notice 任务结束事件
    /// @param taskId 任务 ID
    /// @param totalViewers 总观众数
    /// @param totalPoints 总积分
    event TaskEnded(
        uint256 indexed taskId,
        uint256 totalViewers,
        uint256 totalPoints
    );
    
    /// @notice 奖励领取事件
    /// @param taskId 任务 ID
    /// @param streamer 主播地址
    /// @param reward 奖励金额（扣除手续费后）
    event RewardClaimed(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 reward
    );
    
    /// @notice 质押取回事件
    /// @param taskId 任务 ID
    /// @param streamer 主播地址
    /// @param amount 取回金额
    event Unstaked(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 amount
    );

    /// @notice 观众数据更新事件
    /// @param taskId 任务 ID
    /// @param totalViewers 总观众数
    /// @param totalPoints 总积分
    event ViewerDataUpdated(
        uint256 indexed taskId,
        uint256 totalViewers,
        uint256 totalPoints
    );

    // ============ 构造函数 ============
    
    /// @notice 部署合约并初始化
    /// @param attToken_ ATT 代币合约地址
    /// @param feeCollector_ 手续费收集地址
    constructor(
        IERC20 attToken_,
        address feeCollector_
    ) Ownable(msg.sender) {
        // 确保代币地址有效
        require(address(attToken_) != address(0), "Pool: invalid token");
        // 确保手续费收集地址有效
        require(feeCollector_ != address(0), "Pool: invalid fee collector");
        attToken = attToken_;
        feeCollector = feeCollector_;
    }

    // ============ 外部函数 ============
    
    /// @notice 创建直播任务（质押 ATT 代币）
    /// @dev 使用 nonReentrant 防止重入攻击
    /// @param stakedAmount 质押金额（wei 单位）
    /// @param duration 直播持续时间（秒）
    /// @param rewardRate 奖励率（基点，100 = 1%）
    /// @return taskId 创建的任务 ID
    function createStreamingTask(
        uint256 stakedAmount,
        uint256 duration,
        uint256 rewardRate
    ) external nonReentrant returns (uint256 taskId) {
        // 验证质押金额不低于最低要求
        require(stakedAmount >= minStakeAmount, "Pool: stake too low");
        // 验证持续时间至少 10 秒（测试配置）
        require(duration >= 10, "Pool: min 10 seconds");
        // 验证持续时间不超过 24 小时
        require(duration <= 86400, "Pool: max 24 hours");
        // 验证奖励率在 1% 到 50% 之间
        require(rewardRate >= 100 && rewardRate <= 5000, "Pool: invalid reward rate");

        // 生成新的任务 ID
        taskId = nextTaskId++;
        
        // 创建任务并存储
        tasks[taskId] = StreamingTask({
            streamer: msg.sender,           // 主播地址
            stakedAmount: stakedAmount,     // 质押金额
            startTime: block.timestamp,     // 当前区块时间戳
            endTime: block.timestamp + duration,  // 结束时间
            duration: duration,             // 持续时间
            rewardRate: rewardRate,         // 奖励率
            totalViewers: 0,                // 初始观众数为 0
            totalPoints: 0,                 // 初始积分为 0
            streamerReward: 0,              // 初始奖励为 0
            status: TaskStatus.Active,      // 状态设为进行中
            unstakeTime: 0                  // 取回时间未设置
        });

        // 将任务 ID 添加到主播的任务列表
        streamerTasks[msg.sender].push(taskId);

        // 将质押的代币从主播转移到合约
        // 注意：主播需要先调用 ATT.approve(poolAddress, amount)
        attToken.safeTransferFrom(msg.sender, address(this), stakedAmount);

        // 触发任务创建事件
        emit TaskCreated(taskId, msg.sender, stakedAmount, duration, rewardRate);
    }

    /// @notice 更新观众参与数据（由后端/预言机调用）
    /// @dev 只有合约所有者可以调用
    /// @param taskId 任务 ID
    /// @param totalViewers 总观众数
    /// @param totalPoints 总积分
    function updateViewerData(
        uint256 taskId,
        uint256 totalViewers,
        uint256 totalPoints
    ) external onlyOwner {
        // 获取任务的存储引用（storage 表示直接修改链上数据）
        StreamingTask storage task = tasks[taskId];
        // 验证任务存在（主播地址不为零地址）
        require(task.streamer != address(0), "Pool: task not found");
        // 验证任务状态为进行中
        require(task.status == TaskStatus.Active, "Pool: task not active");

        // 更新观众数据
        task.totalViewers = totalViewers;
        task.totalPoints = totalPoints;

        // 触发数据更新事件
        emit ViewerDataUpdated(taskId, totalViewers, totalPoints);
    }

    /// @notice 结束直播任务并计算奖励
    /// @dev 只有主播本人或合约所有者可以调用
    /// @param taskId 任务 ID
    function endStreamingTask(uint256 taskId) external {
        StreamingTask storage task = tasks[taskId];
        // 验证任务存在
        require(task.streamer != address(0), "Pool: task not found");
        // 验证任务状态为进行中
        require(task.status == TaskStatus.Active, "Pool: task not active");
        // 验证调用者是主播本人或合约所有者
        require(
            msg.sender == task.streamer || msg.sender == owner(),
            "Pool: not authorized"
        );
        // 验证已到达结束时间
        require(block.timestamp >= task.endTime, "Pool: task not ended yet");

        // ============ 计算主播奖励 ============
        // 奖励公式：基础奖励 = 质押金额 × 奖励率 / 10000
        // 例如：1000 ATT × 500 / 10000 = 50 ATT
        uint256 baseReward = (task.stakedAmount * task.rewardRate) / 10000;
        
        // 参与度乘数：观众数越多，奖励越高
        // 如果没有观众，乘数为 1（保底奖励）
        uint256 engagementMultiplier = task.totalViewers > 0 ? task.totalViewers : 1;
        
        // 总奖励 = 基础奖励 × 观众数 / 100
        // 例如：50 ATT × 10 观众 / 100 = 5 ATT
        uint256 totalReward = (baseReward * engagementMultiplier) / 100;

        // 奖励上限：不超过质押金额的 50%
        uint256 maxReward = task.stakedAmount / 2;
        if (totalReward > maxReward) {
            totalReward = maxReward;
        }

        // 保存计算出的奖励
        task.streamerReward = totalReward;
        // 更新任务状态为已结束
        task.status = TaskStatus.Ended;

        // 触发任务结束事件
        emit TaskEnded(taskId, task.totalViewers, task.totalPoints);
    }

    /// @notice 领取主播奖励
    /// @dev 使用 nonReentrant 防止重入攻击
    /// @param taskId 任务 ID
    function claimStreamerReward(uint256 taskId) external nonReentrant {
        StreamingTask storage task = tasks[taskId];
        // 验证调用者是主播本人
        require(task.streamer == msg.sender, "Pool: not streamer");
        // 验证任务状态为已结束
        require(task.status == TaskStatus.Ended, "Pool: task not ended");

        uint256 reward = task.streamerReward;
        // 验证有奖励可领取
        require(reward > 0, "Pool: no reward");

        // ============ 计算手续费 ============
        // 平台手续费 = 奖励 × 手续费率 / 10000
        // 例如：100 ATT × 500 / 10000 = 5 ATT（5%）
        uint256 fee = (reward * platformFeeRate) / 10000;
        // 净奖励 = 总奖励 - 手续费
        uint256 netReward = reward - fee;

        // 更新任务状态为已领取
        task.status = TaskStatus.Claimed;
        // 设置可以取回质押的时间（当前时间 + 冷却期）
        task.unstakeTime = block.timestamp + unstakeCooldown;

        // ============ 转账奖励 ============
        // 如果有手续费，先转给手续费收集地址
        if (fee > 0) {
            attToken.safeTransfer(feeCollector, fee);
        }
        // 将净奖励转给主播
        attToken.safeTransfer(msg.sender, netReward);

        // 触发奖励领取事件
        emit RewardClaimed(taskId, msg.sender, netReward);
    }

    /// @notice 取回质押的代币（需等待冷却期）
    /// @dev 使用 nonReentrant 防止重入攻击
    /// @param taskId 任务 ID
    function unstake(uint256 taskId) external nonReentrant {
        StreamingTask storage task = tasks[taskId];
        // 验证调用者是主播本人
        require(task.streamer == msg.sender, "Pool: not streamer");
        // 验证奖励已领取
        require(task.status == TaskStatus.Claimed, "Pool: rewards not claimed");
        // 验证取回时间已设置
        require(task.unstakeTime > 0, "Pool: unstake time not set");
        // 验证冷却期已过
        require(block.timestamp >= task.unstakeTime, "Pool: cooldown not passed");

        // 获取质押金额
        uint256 amount = task.stakedAmount;
        // 更新任务状态为已取回
        task.status = TaskStatus.Unstaked;
        // 清零质押金额（防止重复取回）
        task.stakedAmount = 0;

        // 将质押的代币返还给主播
        attToken.safeTransfer(msg.sender, amount);

        // 触发取回事件
        emit Unstaked(taskId, msg.sender, amount);
    }

    // ============ 查询函数 ============
    
    /// @notice 获取主播的所有任务 ID
    /// @param streamer 主播地址
    /// @return 任务 ID 数组
    function getStreamerTasks(address streamer) external view returns (uint256[] memory) {
        return streamerTasks[streamer];
    }

    /// @notice 获取任务详情
    /// @param taskId 任务 ID
    /// @return 任务结构体
    function getTask(uint256 taskId) external view returns (StreamingTask memory) {
        return tasks[taskId];
    }

    // ============ 管理函数（仅限所有者）============
    
    /// @notice 更新最低质押金额
    /// @param newAmount 新的最低金额
    function setMinStakeAmount(uint256 newAmount) external onlyOwner {
        minStakeAmount = newAmount;
    }

    /// @notice 更新取回冷却期
    /// @param newCooldown 新的冷却期（秒）
    function setUnstakeCooldown(uint256 newCooldown) external onlyOwner {
        unstakeCooldown = newCooldown;
    }

    /// @notice 更新平台手续费率
    /// @param newRate 新的手续费率（基点）
    function setPlatformFeeRate(uint256 newRate) external onlyOwner {
        // 限制最高 10%
        require(newRate <= 1000, "Pool: fee too high");
        platformFeeRate = newRate;
    }

    /// @notice 更新手续费收集地址
    /// @param newCollector 新的收集地址
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Pool: invalid collector");
        feeCollector = newCollector;
    }
}
