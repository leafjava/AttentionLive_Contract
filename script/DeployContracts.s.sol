// SPDX-License-Identifier: MIT
pragma solidity ^0.8.23;

import {Script} from "forge-std/Script.sol";
import {console} from "forge-std/console.sol";
import {AttentionToken} from "../src/AttentionToken.sol";
import {StreamerStakingPool} from "../src/StreamerStakingPool.sol";
import {ViewerRewardPool} from "../src/ViewerRewardPool.sol";

contract DeployContracts is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);

        console.log("Deploying contracts with account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy AttentionToken
        AttentionToken attToken = new AttentionToken();
        console.log("AttentionToken deployed at:", address(attToken));

        // 2. Deploy StreamerStakingPool
        StreamerStakingPool stakingPool = new StreamerStakingPool(
            attToken,
            deployer // Fee collector is deployer for now
        );
        console.log("StreamerStakingPool deployed at:", address(stakingPool));

        // 3. Deploy ViewerRewardPool
        ViewerRewardPool rewardPool = new ViewerRewardPool(attToken);
        console.log("ViewerRewardPool deployed at:", address(rewardPool));

        // 4. Fund ViewerRewardPool with initial tokens (10 million ATT)
        uint256 rewardPoolFunding = 10_000_000 * 10**18;
        attToken.transfer(address(rewardPool), rewardPoolFunding);
        console.log("ViewerRewardPool funded with:", rewardPoolFunding / 10**18, "ATT");

        // 5. Fund StreamerStakingPool with reward tokens (5 million ATT)
        uint256 stakingPoolFunding = 5_000_000 * 10**18;
        attToken.transfer(address(stakingPool), stakingPoolFunding);
        console.log("StreamerStakingPool funded with:", stakingPoolFunding / 10**18, "ATT");

        vm.stopBroadcast();

        console.log("\n=== Deployment Summary ===");
        console.log("AttentionToken:", address(attToken));
        console.log("StreamerStakingPool:", address(stakingPool));
        console.log("ViewerRewardPool:", address(rewardPool));
        console.log("Deployer:", deployer);
    }
}
