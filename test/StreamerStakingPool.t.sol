// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Test} from "forge-std/Test.sol";
import {AttentionToken} from "../src/AttentionToken.sol";
import {StreamerStakingPool} from "../src/StreamerStakingPool.sol";

contract StreamerStakingPoolTest is Test {
    AttentionToken public attToken;
    StreamerStakingPool public stakingPool;
    
    address public owner = address(1);
    address public streamer = address(2);
    address public feeCollector = address(3);
    
    uint256 constant INITIAL_BALANCE = 100_000 * 10**18;

    function setUp() public {
        vm.startPrank(owner);
        
        attToken = new AttentionToken();
        stakingPool = new StreamerStakingPool(attToken, feeCollector);
        
        // Transfer tokens to streamer
        attToken.transfer(streamer, INITIAL_BALANCE);
        
        vm.stopPrank();
    }

    function testCreateStreamingTask() public {
        uint256 stakeAmount = 5000 * 10**18;
        uint256 duration = 3600; // 1 hour
        uint256 rewardRate = 500; // 5%

        vm.startPrank(streamer);
        attToken.approve(address(stakingPool), stakeAmount);
        
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, duration, rewardRate);
        
        assertEq(taskId, 1);
        
        (
            address taskStreamer,
            uint256 stakedAmount,
            ,
            ,
            ,
            ,
            ,
            ,
            ,
            StreamerStakingPool.TaskStatus status,
        ) = stakingPool.tasks(taskId);
        
        assertEq(taskStreamer, streamer);
        assertEq(stakedAmount, stakeAmount);
        assertEq(uint(status), uint(StreamerStakingPool.TaskStatus.Active));
        
        vm.stopPrank();
    }

    function testEndStreamingTask() public {
        // Create task
        uint256 stakeAmount = 5000 * 10**18;
        uint256 duration = 3600;
        uint256 rewardRate = 500;

        vm.startPrank(streamer);
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, duration, rewardRate);
        vm.stopPrank();

        // Update viewer data
        vm.prank(owner);
        stakingPool.updateViewerData(taskId, 100, 5000);

        // Fast forward time
        vm.warp(block.timestamp + duration + 1);

        // End task
        vm.prank(streamer);
        stakingPool.endStreamingTask(taskId);

        (,,,,,,,, uint256 streamerReward, StreamerStakingPool.TaskStatus status,) = stakingPool.tasks(taskId);
        
        assertEq(uint(status), uint(StreamerStakingPool.TaskStatus.Ended));
        assertGt(streamerReward, 0);
    }

    function testClaimReward() public {
        // Create and end task
        uint256 stakeAmount = 5000 * 10**18;
        uint256 duration = 3600;
        uint256 rewardRate = 500;

        vm.startPrank(streamer);
        attToken.approve(address(stakingPool), stakeAmount);
        uint256 taskId = stakingPool.createStreamingTask(stakeAmount, duration, rewardRate);
        vm.stopPrank();

        vm.prank(owner);
        stakingPool.updateViewerData(taskId, 100, 5000);

        vm.warp(block.timestamp + duration + 1);

        vm.prank(streamer);
        stakingPool.endStreamingTask(taskId);

        // Claim reward
        uint256 balanceBefore = attToken.balanceOf(streamer);
        
        vm.prank(streamer);
        stakingPool.claimStreamerReward(taskId);

        uint256 balanceAfter = attToken.balanceOf(streamer);
        assertGt(balanceAfter, balanceBefore);
    }
}
