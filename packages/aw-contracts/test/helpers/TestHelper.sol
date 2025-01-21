// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../../script/DeployPKPToolRegistry.s.sol";
import "../../src/PKPToolRegistry.sol";
import "../../src/facets/PKPToolRegistryToolFacet.sol";
import "../../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../../src/libraries/PKPToolRegistryStorage.sol";
import "../mocks/MockPKPNFT.sol";

abstract contract TestHelper is Test {
    using PKPToolRegistryStorage for PKPToolRegistryStorage.Layout;

    // Common test variables
    address public deployer;
    address public nonOwner;
    MockPKPNFT public mockPkpNft;
    PKPToolRegistry public diamond;
    DeployPKPToolRegistry public deployScript;

    // Test constants
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    address constant TEST_DELEGATEE = address(0x123);
    string constant TEST_TOOL_CID = "QmTEST1";
    string constant TEST_TOOL_CID_2 = "QmTEST2";
    string constant TEST_POLICY_CID = "QmPOLICY";

    function setUp() public virtual {
        // Setup deployer account using default test account
        deployer = vm.addr(0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80);
        nonOwner = makeAddr("non-owner");

        // Deploy mock PKP NFT contract
        mockPkpNft = new MockPKPNFT();

        // Set environment variables for deployment
        vm.setEnv("PKP_TOOL_REGISTRY_DEPLOYER_PRIVATE_KEY", "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80");
        
        // Deploy using the script
        deployScript = new DeployPKPToolRegistry();
        address diamondAddress = deployScript.deployToNetwork("test", address(mockPkpNft));
        diamond = PKPToolRegistry(payable(diamondAddress));

        // Set up mock PKP NFT for tests
        mockPkpNft.setOwner(TEST_PKP_TOKEN_ID, deployer);
    }
} 