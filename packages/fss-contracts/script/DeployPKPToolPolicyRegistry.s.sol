// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PKPToolPolicyRegistry.sol";

contract DeployPKPToolPolicyRegistry is Script {
    function run() external {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PKP_TOOL_POLICY_REGISTRY_DEPLOYER_PRIVATE_KEY");
        
        // Get PKP NFT contract address from environment variable
        address pkpNFTAddress = vm.envAddress("PKP_NFT_CONTRACT_ADDRESS");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the registry
        PKPToolPolicyRegistry registry = new PKPToolPolicyRegistry(pkpNFTAddress);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the deployment
        console.log("PKPToolPolicyRegistry deployed to:", address(registry));
        console.log("Using PKP NFT contract:", pkpNFTAddress);
    }
} 