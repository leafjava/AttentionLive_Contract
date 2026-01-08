// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title StreamerStakingPool
/// @notice Staking pool for streamers to stake ATT tokens and earn rewards based on viewer engagement
contract StreamerStakingPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    enum TaskStatus {
        Active,      // Streaming is active
        Ended,       // Streaming ended, rewards claimable
        Claimed,     // Rewards claimed
        Unstaked     // Tokens unstaked
    }

    struct StreamingTask {
        address streamer;           // Streamer address
        uint256 stakedAmount;       // Amount of ATT staked
        uint256 startTime;          // Task start timestamp
        uint256 endTime;            // Task end timestamp
        uint256 duration;           // Streaming duration in seconds
        uint256 rewardRate;         // Reward rate in basis points (100 = 1%)
        uint256 totalViewers;       // Total verified viewers
        uint256 totalPoints;        // Total points distributed to viewers
        uint256 streamerReward;     // Calculated streamer reward
        TaskStatus status;          // Current task status
        uint256 unstakeTime;        // When tokens can be unstaked (0 if not set)
    }

    IERC20 public immutable attToken;
    
    // Minimum stake amount (1000 ATT)
    uint256 public minStakeAmount = 1000 * 10**18;
    
    // Unstake cooldown period (10 seconds for testing)
    uint256 public unstakeCooldown = 10; // 10 seconds
    
    // Platform fee rate (5% = 500 basis points)
    uint256 public platformFeeRate = 500;
    
    // Platform fee collector
    address public feeCollector;

    mapping(uint256 => StreamingTask) public tasks;
    mapping(address => uint256[]) public streamerTasks;
    uint256 public nextTaskId = 1;

    event TaskCreated(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 stakedAmount,
        uint256 duration,
        uint256 rewardRate
    );
    
    event TaskEnded(
        uint256 indexed taskId,
        uint256 totalViewers,
        uint256 totalPoints
    );
    
    event RewardClaimed(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 reward
    );
    
    event Unstaked(
        uint256 indexed taskId,
        address indexed streamer,
        uint256 amount
    );

    event ViewerDataUpdated(
        uint256 indexed taskId,
        uint256 totalViewers,
        uint256 totalPoints
    );

    constructor(
        IERC20 attToken_,
        address feeCollector_
    ) Ownable(msg.sender) {
        require(address(attToken_) != address(0), "Pool: invalid token");
        require(feeCollector_ != address(0), "Pool: invalid fee collector");
        attToken = attToken_;
        feeCollector = feeCollector_;
    }

    /// @notice Create a new streaming task by staking ATT tokens
    function createStreamingTask(
        uint256 stakedAmount,
        uint256 duration,
        uint256 rewardRate
    ) external nonReentrant returns (uint256 taskId) {
        require(stakedAmount >= minStakeAmount, "Pool: stake too low");
        require(duration >= 10, "Pool: min 10 seconds"); // At least 10 seconds for testing
        require(duration <= 86400, "Pool: max 24 hours"); // Max 24 hours
        require(rewardRate >= 100 && rewardRate <= 5000, "Pool: invalid reward rate"); // 1% to 50%

        taskId = nextTaskId++;
        
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

        streamerTasks[msg.sender].push(taskId);

        // Transfer staked tokens to contract
        attToken.safeTransferFrom(msg.sender, address(this), stakedAmount);

        emit TaskCreated(taskId, msg.sender, stakedAmount, duration, rewardRate);
    }

    /// @notice Update viewer engagement data (called by backend/oracle)
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

    /// @notice End streaming task and calculate rewards
    function endStreamingTask(uint256 taskId) external {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer != address(0), "Pool: task not found");
        require(task.status == TaskStatus.Active, "Pool: task not active");
        require(
            msg.sender == task.streamer || msg.sender == owner(),
            "Pool: not authorized"
        );
        require(block.timestamp >= task.endTime, "Pool: task not ended yet");

        // Calculate streamer reward based on engagement
        // Reward = stakedAmount * rewardRate * (totalViewers / 100) / 10000
        // This gives higher rewards for more viewer engagement
        uint256 baseReward = (task.stakedAmount * task.rewardRate) / 10000;
        uint256 engagementMultiplier = task.totalViewers > 0 ? task.totalViewers : 1;
        uint256 totalReward = (baseReward * engagementMultiplier) / 100;

        // Cap reward at 50% of staked amount
        uint256 maxReward = task.stakedAmount / 2;
        if (totalReward > maxReward) {
            totalReward = maxReward;
        }

        task.streamerReward = totalReward;
        task.status = TaskStatus.Ended;

        emit TaskEnded(taskId, task.totalViewers, task.totalPoints);
    }

    /// @notice Claim streamer rewards
    function claimStreamerReward(uint256 taskId) external nonReentrant {
        StreamingTask storage task = tasks[taskId];
        require(task.streamer == msg.sender, "Pool: not streamer");
        require(task.status == TaskStatus.Ended, "Pool: task not ended");

        uint256 reward = task.streamerReward;
        require(reward > 0, "Pool: no reward");

        // Calculate platform fee
        uint256 fee = (reward * platformFeeRate) / 10000;
        uint256 netReward = reward - fee;

        task.status = TaskStatus.Claimed;
        task.unstakeTime = block.timestamp + unstakeCooldown;

        // Transfer rewards
        if (fee > 0) {
            attToken.safeTransfer(feeCollector, fee);
        }
        attToken.safeTransfer(msg.sender, netReward);

        emit RewardClaimed(taskId, msg.sender, netReward);
    }

    /// @notice Unstake tokens after cooldown period
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

    /// @notice Get all tasks for a streamer
    function getStreamerTasks(address streamer) external view returns (uint256[] memory) {
        return streamerTasks[streamer];
    }

    /// @notice Get task details
    function getTask(uint256 taskId) external view returns (StreamingTask memory) {
        return tasks[taskId];
    }

    /// @notice Update minimum stake amount (owner only)
    function setMinStakeAmount(uint256 newAmount) external onlyOwner {
        minStakeAmount = newAmount;
    }

    /// @notice Update unstake cooldown (owner only)
    function setUnstakeCooldown(uint256 newCooldown) external onlyOwner {
        unstakeCooldown = newCooldown;
    }

    /// @notice Update platform fee rate (owner only)
    function setPlatformFeeRate(uint256 newRate) external onlyOwner {
        require(newRate <= 1000, "Pool: fee too high"); // Max 10%
        platformFeeRate = newRate;
    }

    /// @notice Update fee collector (owner only)
    function setFeeCollector(address newCollector) external onlyOwner {
        require(newCollector != address(0), "Pool: invalid collector");
        feeCollector = newCollector;
    }
}
