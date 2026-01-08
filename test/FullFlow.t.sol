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
        
        console.log("=== Setup Complete ===");
        console.log("ATT Token:", address(attToken));
        console.log("Staking Pool:", address(stakingPool));
        console.log("Reward Pool:", address(rewardPool));
        console.log("");
    }
    
    function testFullFlow() public {
        console.log("=== Starting Full Flow Test ===");
        console.log("");
        
        // 1. 主播创建任务
        console.log("Step 1: Streamer creates staking task");
        vm.startPrank(streamer);
        
        uint256 stakeAmount = 10_000 * 10**18;
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, 3600, 500);
        
        console.log("  Task ID:", taskId);
        console.log("  Staked Amount:", stakeAmount / 10**18, "ATT");
        console.log("  Duration: 3600 seconds (1 hour)");
        console.log("  Reward Rate: 500 (5%)");
        vm.stopPrank();
        console.log("");
        
        // 2. 更新观众数据
        console.log("Step 2: Update viewer engagement data");
        vm.prank(owner);
        stakingPool.updateViewerData(taskId, 100, 5000);
        console.log("  Total Viewers: 100");
        console.log("  Total Points: 5000");
        console.log("");
        
        // 3. 快进时间
        console.log("Step 3: Fast forward time");
        vm.warp(block.timestamp + 3601);
        console.log("  Time advanced: 3601 seconds");
        console.log("");
        
        // 4. 结束任务
        console.log("Step 4: End streaming task");
        vm.prank(streamer);
        stakingPool.endStreamingTask(taskId);
        console.log("  Task ended successfully");
        console.log("");
        
        // 5. 领取奖励
        console.log("Step 5: Claim streamer reward");
        uint256 balanceBefore = attToken.balanceOf(streamer);
        vm.prank(streamer);
        stakingPool.claimStreamerReward(taskId);
        uint256 balanceAfter = attToken.balanceOf(streamer);
        uint256 reward = balanceAfter - balanceBefore;
        
        console.log("  Balance before:", balanceBefore / 10**18, "ATT");
        console.log("  Balance after:", balanceAfter / 10**18, "ATT");
        console.log("  Reward received:", reward / 10**18, "ATT");
        console.log("");
        
        // 验证奖励计算
        assertGt(reward, 0, "Reward should be greater than 0");
        
        // 6. 观众获得积分
        console.log("Step 6: Add points to viewer");
        vm.prank(owner);
        rewardPool.addPoints(viewer, 5000, taskId);
        console.log("  Points added: 5000");
        console.log("");
        
        // 7. 观众兑换奖励
        console.log("Step 7: Viewer claims reward");
        uint256 viewerBalanceBefore = attToken.balanceOf(viewer);
        vm.prank(viewer);
        rewardPool.claimReward();
        uint256 viewerBalanceAfter = attToken.balanceOf(viewer);
        uint256 viewerReward = viewerBalanceAfter - viewerBalanceBefore;
        
        console.log("  Balance before:", viewerBalanceBefore / 10**18, "ATT");
        console.log("  Balance after:", viewerBalanceAfter / 10**18, "ATT");
        console.log("  Reward received:", viewerReward / 10**18, "ATT");
        console.log("");
        
        // 验证观众奖励
        assertEq(viewerReward, 5 * 10**18, "Viewer should receive 5 ATT (5000 points / 1000)");
        
        console.log("=== Full Flow Test Complete! ===");
        console.log("");
    }
    
    function testMultipleViewers() public {
        console.log("=== Testing Multiple Viewers ===");
        console.log("");
        
        // 创建任务
        vm.startPrank(streamer);
        uint256 stakeAmount = 10_000 * 10**18;
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, 3600, 500);
        vm.stopPrank();
        
        // 批量添加积分
        address[] memory viewers = new address[](3);
        viewers[0] = address(10);
        viewers[1] = address(11);
        viewers[2] = address(12);
        
        uint256[] memory points = new uint256[](3);
        points[0] = 2000;
        points[1] = 3000;
        points[2] = 1500;
        
        vm.prank(owner);
        rewardPool.batchAddPoints(viewers, points, taskId);
        
        console.log("Batch added points to 3 viewers");
        console.log("  Viewer 1: 2000 points");
        console.log("  Viewer 2: 3000 points");
        console.log("  Viewer 3: 1500 points");
        console.log("");
        
        // 验证积分
        (uint256 totalPoints1,,,, ) = rewardPool.viewers(viewers[0]);
        (uint256 totalPoints2,,,, ) = rewardPool.viewers(viewers[1]);
        (uint256 totalPoints3,,,, ) = rewardPool.viewers(viewers[2]);
        
        assertEq(totalPoints1, 2000, "Viewer 1 should have 2000 points");
        assertEq(totalPoints2, 3000, "Viewer 2 should have 3000 points");
        assertEq(totalPoints3, 1500, "Viewer 3 should have 1500 points");
        
        console.log("=== Multiple Viewers Test Complete! ===");
        console.log("");
    }
    
    function testUnstakeAfterCooldown() public {
        console.log("=== Testing Unstake After Cooldown ===");
        console.log("");
        
        // 创建并完成任务
        vm.startPrank(streamer);
        uint256 stakeAmount = 10_000 * 10**18;
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, 3600, 500);
        vm.stopPrank();
        
        vm.prank(owner);
        stakingPool.updateViewerData(taskId, 50, 2500);
        
        vm.warp(block.timestamp + 3601);
        
        vm.prank(streamer);
        stakingPool.endStreamingTask(taskId);
        
        vm.prank(streamer);
        stakingPool.claimStreamerReward(taskId);
        
        console.log("Task completed and reward claimed");
        console.log("");
        
        // 尝试立即提取（应该失败）
        console.log("Attempting to unstake immediately (should fail)...");
        vm.prank(streamer);
        vm.expectRevert("Pool: cooldown not passed");
        stakingPool.unstake(taskId);
        console.log("  Failed as expected");
        console.log("");
        
        // 快进冷却期
        console.log("Fast forwarding 7 days...");
        vm.warp(block.timestamp + 7 days);
        console.log("");
        
        // 提取质押
        console.log("Unstaking after cooldown...");
        uint256 balanceBefore = attToken.balanceOf(streamer);
        vm.prank(streamer);
        stakingPool.unstake(taskId);
        uint256 balanceAfter = attToken.balanceOf(streamer);
        
        console.log("  Balance before:", balanceBefore / 10**18, "ATT");
        console.log("  Balance after:", balanceAfter / 10**18, "ATT");
        console.log("  Unstaked amount:", (balanceAfter - balanceBefore) / 10**18, "ATT");
        console.log("");
        
        assertEq(balanceAfter - balanceBefore, stakeAmount, "Should receive full stake back");
        
        console.log("=== Unstake Test Complete! ===");
        console.log("");
    }
}
