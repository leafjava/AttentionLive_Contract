// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

// 导入 OpenZeppelin 的 ERC20 接口
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// 导入 OpenZeppelin 的安全 ERC20 操作库
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// 导入 OpenZeppelin 的所有权管理合约
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
// 导入 OpenZeppelin 的重入攻击防护合约
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ViewerRewardPool（观众奖励池）
/// @notice 为完成观看任务的观众分发奖励的池子
/// @dev 观众通过观看直播获得积分，积分可以兑换成 ATT 代币
contract ViewerRewardPool is Ownable, ReentrancyGuard {
    // 使用 SafeERC20 库来安全地操作 ERC20 代币
    using SafeERC20 for IERC20;

    // ============ 数据结构 ============
    
    /// @notice 观众账户结构体
    /// @dev 存储单个观众的积分和领取记录
    struct ViewerAccount {
        uint256 totalPoints;        // 累计获得的总积分
        uint256 claimedPoints;      // 已兑换成代币的积分
        uint256 pendingPoints;      // 待兑换的积分
        uint256 totalClaimed;       // 累计领取的 ATT 代币数量（wei 单位）
        uint256 lastClaimTime;      // 上次领取的时间戳
    }

    // ============ 状态变量 ============
    
    /// @notice ATT 代币合约地址（不可变）
    IERC20 public immutable attToken;
    
    /// @notice 积分到 ATT 的兑换率（1000 积分 = 1 ATT）
    /// @dev 例如：1000 积分可以兑换 1 个 ATT（10^18 wei）
    uint256 public pointsPerToken = 1000;
    
    /// @notice 最低兑换积分（1000 积分 = 1 ATT）
    /// @dev 必须累积至少这么多积分才能兑换
    uint256 public minClaimPoints = 1000;
    
    /// @notice 兑换冷却期（1 小时）
    /// @dev 两次兑换之间必须间隔这么长时间
    uint256 public claimCooldown = 1 hours;

    /// @notice 观众地址到账户信息的映射
    mapping(address => ViewerAccount) public viewers;
    
    // ============ 全局统计 ============
    
    /// @notice 累计分发的总积分
    uint256 public totalPointsDistributed;
    
    /// @notice 累计兑换的总代币数量
    uint256 public totalTokensClaimed;
    
    /// @notice 总观众数
    uint256 public totalViewers;

    // ============ 事件 ============
    
    /// @notice 积分添加事件
    /// @param viewer 观众地址
    /// @param points 添加的积分数
    /// @param taskId 关联的任务 ID
    event PointsAdded(address indexed viewer, uint256 points, uint256 taskId);
    
    /// @notice 奖励领取事件
    /// @param viewer 观众地址
    /// @param points 兑换的积分数
    /// @param tokens 获得的代币数量
    event RewardClaimed(address indexed viewer, uint256 points, uint256 tokens);
    
    /// @notice 兑换率更新事件
    /// @param oldRate 旧兑换率
    /// @param newRate 新兑换率
    event PointsPerTokenUpdated(uint256 oldRate, uint256 newRate);

    // ============ 构造函数 ============
    
    /// @notice 部署合约并初始化
    /// @param attToken_ ATT 代币合约地址
    constructor(IERC20 attToken_) Ownable(msg.sender) {
        require(address(attToken_) != address(0), "Pool: invalid token");
        attToken = attToken_;
    }

    // ============ 外部函数 ============
    
    /// @notice 为观众添加积分（由后端验证后调用）
    /// @dev 只有合约所有者可以调用
    /// @param viewer 观众地址
    /// @param points 添加的积分数
    /// @param taskId 关联的任务 ID
    function addPoints(
        address viewer,
        uint256 points,
        uint256 taskId
    ) external onlyOwner {
        // 验证观众地址有效
        require(viewer != address(0), "Pool: invalid viewer");
        // 验证积分大于 0
        require(points > 0, "Pool: zero points");

        // 获取观众账户的存储引用
        ViewerAccount storage account = viewers[viewer];
        
        // 如果是新观众（总积分为 0），增加观众计数
        if (account.totalPoints == 0) {
            totalViewers++;
        }

        // 更新观众账户数据
        account.totalPoints += points;      // 累计总积分
        account.pendingPoints += points;    // 增加待兑换积分
        totalPointsDistributed += points;   // 更新全局统计

        // 触发积分添加事件
        emit PointsAdded(viewer, points, taskId);
    }

    /// @notice 批量为多个观众添加积分
    /// @dev 只有合约所有者可以调用，用于提高效率
    /// @param viewerList 观众地址数组
    /// @param pointsList 对应的积分数组
    /// @param taskId 关联的任务 ID
    function batchAddPoints(
        address[] calldata viewerList,
        uint256[] calldata pointsList,
        uint256 taskId
    ) external onlyOwner {
        // 验证两个数组长度相同
        require(viewerList.length == pointsList.length, "Pool: length mismatch");
        
        // 遍历所有观众
        for (uint256 i = 0; i < viewerList.length; i++) {
            address viewer = viewerList[i];
            uint256 points = pointsList[i];
            
            // 跳过无效数据
            if (viewer == address(0) || points == 0) continue;

            ViewerAccount storage account = viewers[viewer];
            
            // 如果是新观众，增加计数
            if (account.totalPoints == 0) {
                totalViewers++;
            }

            // 更新账户数据
            account.totalPoints += points;
            account.pendingPoints += points;
            totalPointsDistributed += points;

            // 触发事件
            emit PointsAdded(viewer, points, taskId);
        }
    }

    /// @notice 兑换 ATT 代币（将积分转换为代币）
    /// @dev 使用 nonReentrant 防止重入攻击
    function claimReward() external nonReentrant {
        ViewerAccount storage account = viewers[msg.sender];
        
        // 验证待兑换积分达到最低要求
        require(account.pendingPoints >= minClaimPoints, "Pool: insufficient points");
        // 验证冷却期已过
        require(
            block.timestamp >= account.lastClaimTime + claimCooldown,
            "Pool: cooldown not passed"
        );

        // 获取待兑换的积分
        uint256 pointsToClaim = account.pendingPoints;
        
        // ============ 计算可获得的代币数量 ============
        // 公式：代币数量 = (积分 × 10^18) / 兑换率
        // 例如：1000 积分 / 1000 = 1 ATT (10^18 wei)
        uint256 tokensToReceive = (pointsToClaim * 10**18) / pointsPerToken;

        // 验证计算结果大于 0
        require(tokensToReceive > 0, "Pool: zero tokens");
        // 验证池子有足够的代币
        require(
            attToken.balanceOf(address(this)) >= tokensToReceive,
            "Pool: insufficient balance"
        );

        // 更新账户数据
        account.claimedPoints += pointsToClaim;     // 增加已兑换积分
        account.pendingPoints = 0;                  // 清空待兑换积分
        account.totalClaimed += tokensToReceive;    // 增加累计领取
        account.lastClaimTime = block.timestamp;    // 更新领取时间
        
        // 更新全局统计
        totalTokensClaimed += tokensToReceive;

        // 将代币转给观众
        attToken.safeTransfer(msg.sender, tokensToReceive);

        // 触发领取事件
        emit RewardClaimed(msg.sender, pointsToClaim, tokensToReceive);
    }

    // ============ 查询函数 ============
    
    /// @notice 获取观众账户详情
    /// @param viewer 观众地址
    /// @return 观众账户结构体
    function getViewerAccount(address viewer) external view returns (ViewerAccount memory) {
        return viewers[viewer];
    }

    /// @notice 计算观众可兑换的代币数量
    /// @param viewer 观众地址
    /// @return 可兑换的代币数量（wei 单位）
    function getClaimableTokens(address viewer) external view returns (uint256) {
        ViewerAccount storage account = viewers[viewer];
        // 如果积分不足，返回 0
        if (account.pendingPoints < minClaimPoints) {
            return 0;
        }
        // 计算可兑换的代币数量
        return (account.pendingPoints * 10**18) / pointsPerToken;
    }

    /// @notice 检查观众是否可以立即兑换
    /// @param viewer 观众地址
    /// @return 是否可以兑换
    function canClaim(address viewer) external view returns (bool) {
        ViewerAccount storage account = viewers[viewer];
        // 积分足够 且 冷却期已过
        return account.pendingPoints >= minClaimPoints &&
               block.timestamp >= account.lastClaimTime + claimCooldown;
    }

    // ============ 管理函数（仅限所有者）============
    
    /// @notice 更新积分兑换率
    /// @param newRate 新的兑换率（多少积分兑换 1 ATT）
    function setPointsPerToken(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Pool: invalid rate");
        uint256 oldRate = pointsPerToken;
        pointsPerToken = newRate;
        emit PointsPerTokenUpdated(oldRate, newRate);
    }

    /// @notice 更新最低兑换积分
    /// @param newMin 新的最低积分
    function setMinClaimPoints(uint256 newMin) external onlyOwner {
        minClaimPoints = newMin;
    }

    /// @notice 更新兑换冷却期
    /// @param newCooldown 新的冷却期（秒）
    function setClaimCooldown(uint256 newCooldown) external onlyOwner {
        claimCooldown = newCooldown;
    }

    /// @notice 提取代币（仅限所有者，用于紧急情况）
    /// @param amount 提取数量
    function withdrawTokens(uint256 amount) external onlyOwner {
        attToken.safeTransfer(owner(), amount);
    }

    /// @notice 向池子存入代币（任何人都可以为池子充值）
    /// @param amount 存入数量
    function depositTokens(uint256 amount) external {
        attToken.safeTransferFrom(msg.sender, address(this), amount);
    }
}
