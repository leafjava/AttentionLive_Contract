// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

/// @title ViewerRewardPool
/// @notice Reward distribution pool for viewers who complete watch tasks
contract ViewerRewardPool is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct ViewerAccount {
        uint256 totalPoints;        // Total points earned
        uint256 claimedPoints;      // Points already claimed as tokens
        uint256 pendingPoints;      // Points pending claim
        uint256 totalClaimed;       // Total ATT tokens claimed
        uint256 lastClaimTime;      // Last claim timestamp
    }

    IERC20 public immutable attToken;
    
    // Points to ATT conversion rate (1000 points = 1 ATT)
    uint256 public pointsPerToken = 1000;
    
    // Minimum points required to claim (1000 points = 1 ATT)
    uint256 public minClaimPoints = 1000;
    
    // Claim cooldown (1 hour)
    uint256 public claimCooldown = 1 hours;

    mapping(address => ViewerAccount) public viewers;
    
    // Total statistics
    uint256 public totalPointsDistributed;
    uint256 public totalTokensClaimed;
    uint256 public totalViewers;

    event PointsAdded(address indexed viewer, uint256 points, uint256 taskId);
    event RewardClaimed(address indexed viewer, uint256 points, uint256 tokens);
    event PointsPerTokenUpdated(uint256 oldRate, uint256 newRate);

    constructor(IERC20 attToken_) Ownable(msg.sender) {
        require(address(attToken_) != address(0), "Pool: invalid token");
        attToken = attToken_;
    }

    /// @notice Add points to viewer account (called by backend after verification)
    function addPoints(
        address viewer,
        uint256 points,
        uint256 taskId
    ) external onlyOwner {
        require(viewer != address(0), "Pool: invalid viewer");
        require(points > 0, "Pool: zero points");

        ViewerAccount storage account = viewers[viewer];
        
        // Track new viewer
        if (account.totalPoints == 0) {
            totalViewers++;
        }

        account.totalPoints += points;
        account.pendingPoints += points;
        totalPointsDistributed += points;

        emit PointsAdded(viewer, points, taskId);
    }

    /// @notice Batch add points to multiple viewers
    function batchAddPoints(
        address[] calldata viewerList,
        uint256[] calldata pointsList,
        uint256 taskId
    ) external onlyOwner {
        require(viewerList.length == pointsList.length, "Pool: length mismatch");
        
        for (uint256 i = 0; i < viewerList.length; i++) {
            address viewer = viewerList[i];
            uint256 points = pointsList[i];
            
            if (viewer == address(0) || points == 0) continue;

            ViewerAccount storage account = viewers[viewer];
            
            if (account.totalPoints == 0) {
                totalViewers++;
            }

            account.totalPoints += points;
            account.pendingPoints += points;
            totalPointsDistributed += points;

            emit PointsAdded(viewer, points, taskId);
        }
    }

    /// @notice Claim ATT tokens by converting points
    function claimReward() external nonReentrant {
        ViewerAccount storage account = viewers[msg.sender];
        
        require(account.pendingPoints >= minClaimPoints, "Pool: insufficient points");
        require(
            block.timestamp >= account.lastClaimTime + claimCooldown,
            "Pool: cooldown not passed"
        );

        uint256 pointsToClaim = account.pendingPoints;
        uint256 tokensToReceive = (pointsToClaim * 10**18) / pointsPerToken;

        require(tokensToReceive > 0, "Pool: zero tokens");
        require(
            attToken.balanceOf(address(this)) >= tokensToReceive,
            "Pool: insufficient balance"
        );

        account.claimedPoints += pointsToClaim;
        account.pendingPoints = 0;
        account.totalClaimed += tokensToReceive;
        account.lastClaimTime = block.timestamp;
        
        totalTokensClaimed += tokensToReceive;

        attToken.safeTransfer(msg.sender, tokensToReceive);

        emit RewardClaimed(msg.sender, pointsToClaim, tokensToReceive);
    }

    /// @notice Get viewer account details
    function getViewerAccount(address viewer) external view returns (ViewerAccount memory) {
        return viewers[viewer];
    }

    /// @notice Calculate claimable tokens for a viewer
    function getClaimableTokens(address viewer) external view returns (uint256) {
        ViewerAccount storage account = viewers[viewer];
        if (account.pendingPoints < minClaimPoints) {
            return 0;
        }
        return (account.pendingPoints * 10**18) / pointsPerToken;
    }

    /// @notice Check if viewer can claim now
    function canClaim(address viewer) external view returns (bool) {
        ViewerAccount storage account = viewers[viewer];
        return account.pendingPoints >= minClaimPoints &&
               block.timestamp >= account.lastClaimTime + claimCooldown;
    }

    /// @notice Update points per token rate (owner only)
    function setPointsPerToken(uint256 newRate) external onlyOwner {
        require(newRate > 0, "Pool: invalid rate");
        uint256 oldRate = pointsPerToken;
        pointsPerToken = newRate;
        emit PointsPerTokenUpdated(oldRate, newRate);
    }

    /// @notice Update minimum claim points (owner only)
    function setMinClaimPoints(uint256 newMin) external onlyOwner {
        minClaimPoints = newMin;
    }

    /// @notice Update claim cooldown (owner only)
    function setClaimCooldown(uint256 newCooldown) external onlyOwner {
        claimCooldown = newCooldown;
    }

    /// @notice Withdraw tokens (owner only, for emergency)
    function withdrawTokens(uint256 amount) external onlyOwner {
        attToken.safeTransfer(owner(), amount);
    }

    /// @notice Deposit tokens to pool (anyone can fund the pool)
    function depositTokens(uint256 amount) external {
        attToken.safeTransferFrom(msg.sender, address(this), amount);
    }
}
