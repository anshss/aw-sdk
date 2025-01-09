// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DevERC20.sol";

contract DeployDevERC20Script is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("DEVERC20_DEPLOYER_PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the token with name "Dev Token" and symbol "DEV"
        DevERC20 token = new DevERC20("Dev Token", "DEV");

        vm.stopBroadcast();

        // Log the deployed address
        console.log("DevERC20 deployed to:", address(token));
    }
} 