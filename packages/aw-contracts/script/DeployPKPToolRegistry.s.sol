// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/PKPToolRegistry.sol";

/// @title PKP Tool Registry Deployment Script
/// @notice Foundry script for deploying the PKP Tool Registry to multiple networks
/// @dev Uses environment variables for private key and PKP NFT contract addresses
/// @custom:env PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY - Private key of the deployer
/// @custom:env DATIL_DEV_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil Dev
/// @custom:env DATIL_TEST_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil Test
/// @custom:env DATIL_PKP_NFT_CONTRACT_ADDRESS - PKP NFT contract address on Datil
contract DeployPKPToolRegistry is Script {
    /// @notice Error thrown when required environment variables are missing
    error MissingEnvironmentVariable(string name);

    /// @notice Deploys the PKP Tool Registry to a specific network
    /// @dev Broadcasts transactions using the deployer's private key
    /// @param network The name of the network for logging purposes
    /// @param pkpNFTAddress The address of the PKP NFT contract on the target network
    /// @return address The address of the deployed registry
    function deployToNetwork(string memory network, address pkpNFTAddress) internal returns (address) {
        // Validate PKP NFT address
        if (pkpNFTAddress == address(0)) {
            revert MissingEnvironmentVariable(string.concat(network, " PKP NFT contract address"));
        }

        // Get private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY");
        if (deployerPrivateKey == 0) {
            revert MissingEnvironmentVariable("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY");
        }
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the registry
        PKPToolRegistry registry = new PKPToolRegistry(pkpNFTAddress);
        
        // Stop broadcasting transactions
        vm.stopBroadcast();

        // Log the deployment
        console.log("PKPToolRegistry deployed for", network, "to:", address(registry));
        console.log("Using PKP NFT contract:", pkpNFTAddress);

        return address(registry);
    }

    /// @notice Main entry point - deploys the registry to all networks
    /// @dev Deploys to Datil Dev, Datil Test, and Datil networks in sequence
    function run() external {
        // Deploy for Datil Dev
        address datilDevPkpNFT = vm.envAddress("DATIL_DEV_PKP_NFT_CONTRACT_ADDRESS");
        address datilDevRegistry = deployToNetwork("Datil Dev", datilDevPkpNFT);

        // Deploy for Datil Test
        address datilTestPkpNFT = vm.envAddress("DATIL_TEST_PKP_NFT_CONTRACT_ADDRESS");
        address datilTestRegistry = deployToNetwork("Datil Test", datilTestPkpNFT);

        // Deploy for Datil
        address datilPkpNFT = vm.envAddress("DATIL_PKP_NFT_CONTRACT_ADDRESS");
        address datilRegistry = deployToNetwork("Datil", datilPkpNFT);

        // Log summary of all deployments
        console.log("\nDeployment Summary:");
        console.log("------------------");
        console.log("Datil Dev Registry:", datilDevRegistry);
        console.log("Datil Test Registry:", datilTestRegistry);
        console.log("Datil Registry:", datilRegistry);
    }
} 