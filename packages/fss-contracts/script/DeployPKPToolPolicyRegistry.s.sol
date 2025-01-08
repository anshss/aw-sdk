// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PKPToolPolicyRegistry.sol";

contract DeployPKPToolPolicyRegistry is Script {
    function deployToNetwork(string memory network, address pkpNFTAddress) internal {
        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PKP_TOOL_POLICY_REGISTRY_DEPLOYER_PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the registry
        PKPToolPolicyRegistry registry = new PKPToolPolicyRegistry(pkpNFTAddress);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the deployment
        console.log("PKPToolPolicyRegistry deployed for", network, "to:", address(registry));
        console.log("Using PKP NFT contract:", pkpNFTAddress);
    }

    function run() external {
        // Deploy for Datil Dev
        address datilDevPkpNFT = vm.envAddress("DATIL_DEV_PKP_NFT_CONTRACT_ADDRESS");
        deployToNetwork("Datil Dev", datilDevPkpNFT);

        // Deploy for Datil Test
        address datilTestPkpNFT = vm.envAddress("DATIL_TEST_PKP_NFT_CONTRACT_ADDRESS");
        deployToNetwork("Datil Test", datilTestPkpNFT);

        // Deploy for Datil
        address datilPkpNFT = vm.envAddress("DATIL_PKP_NFT_CONTRACT_ADDRESS");
        deployToNetwork("Datil", datilPkpNFT);
    }
} 