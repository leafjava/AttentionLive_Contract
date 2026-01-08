// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// ============ 导入依赖 ============
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title StreamerStakingPool (主播质押池)
/// @notice 主播通过质押 ATT 代币创建直播任务，根据观众互动获得奖励
/// @dev 继承 Ownable（所有权管理）和 ReentrancyGuard（防重入攻击）
contract StreamerStakingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20; // 使用安全的 ERC20 操作库

    // ============ 枚举类型 ============
    
    /// @notice 任务状态枚举
    enum TaskStatus {
        Active,      // 0: 直播进行中
        Ended,       // 1: 直播已结束，可领取奖励
        Claimed,     // 2: 奖励已领取，等待冷却期
        Unstaked     // 3: 质押已取回
    }

    // ============ 结构体 ============
    
    /// @notice 直播任务结构体
    /// @dev 存储单个直播任务的所有信息
    struct StreamingTask {
        address streamer;           // 主播地址
        uint256 stakedAmount;       // 质押的 ATT 数量
        uint256 startTime;          // 任务开始时间戳
        uint256 endTime;            // 任务结束时间戳
        uint256 duration;           // 直播持续时间（秒）
        uint256 rewardRate;         // 奖励率（基点，100 = 1%）
        uint256 totalViewers;       // 总观众数（由后端更新）
        uint256 totalPoints;        // 分配给观众的总积分
        uint256 streamerReward;     // 计算出的主播奖励
        TaskStatus status;          // 当前任务状态
        uint256 unstakeTime;        // 可以取回质押的时间（0 表示未设置）
    }

    // ============ 状态变量 ============
    
    /// @notice ATT 代币合约地址（不可变）
    IERC20 public immutable attToken;
    
    /// @notice 最低质押金额（1000 ATT）
    uint256 public minStakeAmount = 1000 * 10**18;
    
    /// @notice 取回质押的冷却期（10 秒，用于测试）
    /// @dev 生产环境应设置为 7 天
    uint256 public unstakeCooldown = 10;
    
    /// @notice 平台手续费率（5% = 500 基点）
    /// @dev 基点：10000 = 100%，500 = 5%
    uint256 public platformFeeRate = 500;
    
    /// @notice 平台手续费收集地址
    address public feeCollector;

    /// @notice 任务 ID 到任务信息的映射
    mapping(uint256 => StreamingTask) public tasks;
    
    /// @notice 主播地址到其所有任务 ID 的映射
    mapping(address => uint256[]) public streamerTasks;
    
    /// @notice 下一个任务 ID（从 1 开始）
    uint256 public nextTaskId = 1;

    // ============ 事件 ============
    
    /// @notice 任务创建事件
    event TaskCreated(
        uint256 indexed taskId,      // 任务 ID
        address indexed streamer,    // 主播地址
        uint256 stakedAmount,        // 质押金额
        uint256 duration,            // 持续时间
        uint256 rewardRate           // 奖励率
    );
    
    /// @notice 任务结束事件
    event TaskEnded(
        uint256 indexed taskId,      // 任务 ID
        uint256 totalViewers,        // 总观众数
        uint256 totalPoints          // 总积分
    );
    
    /// @notice 奖励领取事件
    event RewardClaimed(
        uint256 indexed taskId,      // 任务 ID
        address indexed streamer,    // 主播地址
        uint256 reward               // 奖励金额（扣除手续费后）
    );
    
    /// @notice 质押取回事件
    event Unstaked(
        uint256 indexed taskId,      // 任务 ID
        address indexed streamer,    // 主播地址
        uint256 amount               // 取回金额
    );

    /// @notice 观众数据更新事件
    event ViewerDataUpdated(
        uint256 indexed taskId,      // 任务 ID
        uint256 totalViewers,        // 总观众数
        uint256 totalPoints          // 总积分
    );

    // ============ 构造函数 ============
    
    /// @notice 初始化质押池合约
    /// @param attToken_ ATT 代币合约地址
    /// @param feeCollector_ 手续费收集地址
    constructor(
        IERC20 attToken_,
        address feeCollector_
    ) Ownable(msg.sender) {
        require(address(attToken_) != address(0), "Pool: invalid token");
        require(feeCollector_ != address(0), "Pool: invalid fee collector");
        attToken = attToken_;
        feeCollector = feeCollector_;
    }

    // ============ 外部函数 ============
    
    /// @notice 创建新的直播任务（质押 ATT）
    /// @dev 主播调用此函数质押代币并创建任务
    /// @param stakedAmount 质押的 ATT 数量（带 18 位小数）
    /// @param duration 直播持续时间（秒）
    /// @param rewardRate 奖励率（基点，100 = 1%）
    /// @return taskId 新创建的任务 ID
    function createStreamingTask(
        uint256 stakedAmount,
        uint256 duration,
        uint256 rewardRate
    ) external nonReentrant returns (uint256 taskId) {
        // 验证参数
        require(stakedAmount >= minStakeAmount, "Pool: stake too low");
        require(duration >= 10, "Pool: min 10 seconds");
        require(duration <= 86400, "Pool: max 24 hours");
        require(rewardRate >= 100 && rewardRate <= 5000, "Pool: invalid reward rate");

        // 生成新任务 ID
        taskId = nextTaskId++;
        
        // 创建任务
        tasks[taskId] = StreamingTask({
            streamer: msg.sender,
            stakedAmount: stakedAmount,
            startTime: block.timestamp,
            endTime: block.timestamp + duration,
            duration: duration,
            rewardRate: rewardRate,
            totalViewers: 0,
            totalPoints: 0,
            streamerReward: 0,
            status: TaskStatus.Active,
            unstakeTime: 0
        });

        // 记录主播的任务
        streamerTasks[msg.sender].push(taskId);

        // 从主播账户转移质押代币到合约
        attToken.safeTransferFrom(msg.sender, address(this), stakedAmount);

        emit TaskCreated(taskId, msg.sender, stakedAmount, duration, rewardRate);
    }

    /// @notice 更新观众互动数据（仅限 Owner）
    /// @dev 由后端或预言机调用，更新观众数和积分
    /// @param taskId 任务 ID
    /// @param totalViewers 总观众数
    /// @param totalPoints 总积分
    function updateViewerData(
        uint256 taskId,
        uint256 totalViewers,
        uint256 totalPoints
    ) external onlyOwner {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer != address(0), "Pool: task not found");
        require(task.status == TaskStatus.Active, "Pool: task not active");

        task.totalViewers = totalViewers;
        task.totalPoints = totalPoints;

        emit ViewerDataUpdated(taskId, totalViewers, totalPoints);
    }

    /// @notice 结束直播任务并计算奖励
    /// @dev 主播或 Owner 可以调用，必须在任务结束时间后
    /// @param taskId 任务 ID
    function endStreamingTask(uint256 taskId) external {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer != address(0), "Pool: task not found");
        require(task.status == TaskStatus.Active, "Pool: task not active");
        require(
            msg.sender == task.streamer || msg.sender == owner(),
            "Pool: not authorized"
        );
        require(block.timestamp >= task.endTime, "Pool: task not ended yet");

        // 计算主播奖励
        // 公式：基础奖励 = 质押金额 * 奖励率 / 10000
        uint256 baseReward = (task.stakedAmount * task.rewardRate) / 10000;
        
        // 根据观众数调整奖励（观众越多，奖励越高）
        uint256 engagementMultiplier = task.totalViewers > 0 ? task.totalViewers : 1;
        uint256 totalReward = (baseReward * engagementMultiplier) / 100;

        // 奖励上限：质押金额的 50%
        uint256 maxReward = task.stakedAmount / 2;
        if (totalReward > maxReward) {
            totalReward = maxReward;
        }

        task.streamerReward = totalReward;
        task.status = TaskStatus.Ended;

        emit TaskEnded(taskId, task.totalViewers, task.totalPoints);
    }

    /// @notice 领取主播奖励
    /// @dev 主播调用此函数领取奖励（扣除平台手续费）
    /// @param taskId 任务 ID
    function claimStreamerReward(uint256 taskId) external nonReentrant {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer == msg.sender, "Pool: not streamer");
        require(task.status == TaskStatus.Ended, "Pool: task not ended");

        uint256 reward = task.streamerReward;
        require(reward > 0, "Pool: no reward");

        // 计算平台手续费
        uint256 fee = (reward * platformFeeRate) / 10000;
        uint256 netReward = reward - fee;

        // 更新任务状态
        task.status = TaskStatus.Claimed;
        task.unstakeTime = block.timestamp + unstakeCooldown;

        // 转账奖励
        if (fee > 0) {
            attToken.safeTransfer(feeCollector, fee);
        }
        attToken.safeTransfer(msg.sender, netReward);

        emit RewardClaimed(taskId, msg.sender, netReward);
    }

    /// @notice 取回质押的代币
    /// @dev 必须在冷却期后才能取回
    /// @param taskId 任务 ID
    function unstake(uint256 taskId) external nonReentrant {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer == msg.sender, "Pool: not streamer");
        require(task.status == TaskStatus.Claimed, "Pool: rewards not claimed");
        require(task.unstakeTime > 0, "Pool: unstake time not set");
        require(block.timestamp >= task.unstakeTime, "Pool: cooldown not passed");

        uint256 amount = task.stakedAmount;
        task.status = TaskStatus.Unstaked;
        task.stakedAmount = 0;

        attToken.safeTransfer(msg.sender, amount);

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

    // ============ 管理函数（仅限 Owner）============
    
    /// @notice 更新最低质押金额
    function setMinStakeAmount(uint256 newAmount) external onlyOwner {
        minStakeAmount = newAmount;
    }

    /// @notice 更新取回冷却期
    function setUnstakeCooldown(uint256 newCooldown) external onlyOwner {
        unstakeCooldown = newCooldown;
    }

    /// @notice 更新平台手续费率
    function setPlatformFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 1000, "Pool: fee too high"); // 最高 10%
        platformFeeRate = newRate;
    }

    /// @notice 更新手续费收集地址
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Pool: invalid collector");
        feeCollector = newCollector;
    }
}
