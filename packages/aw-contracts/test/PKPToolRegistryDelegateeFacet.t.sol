// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryDelegateeFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/facets/PKPToolRegistryPolicyFacet.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import "../src/libraries/PKPToolRegistryDelegateeEvents.sol";
import "./mocks/MockPKPNFT.sol";

contract PKPToolRegistryDelegateeFacetTest is Test {
    // Test addresses
    MockPKPNFT mockPkpNft;
    address deployer;
    address nonOwner;
    
    // Contract instances
    PKPToolRegistry diamond;
    DeployPKPToolRegistry deployScript;
    
    // Test data
    uint256 constant TEST_PKP_TOKEN_ID = 1;
    uint256 constant TEST_PKP_TOKEN_ID_2 = 2;
    address constant TEST_DELEGATEE = address(0x1234);
    address constant TEST_DELEGATEE_2 = address(0x5678);

    // Events to test
    event AddedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
    event RemovedDelegatees(uint256 indexed pkpTokenId, address[] delegatees);

    function setUp() public {
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
        mockPkpNft.setOwner(TEST_PKP_TOKEN_ID_2, deployer);
    }

    /// @notice Test adding a single delegatee
    function test_addSingleDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Expect the AddedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit AddedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add the delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee was added
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be added"
        );

        // Verify PKP is in delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 1, "Wrong number of delegated PKPs");
        assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");

        vm.stopPrank();
    }

    /// @notice Test adding multiple delegatees
    function test_addMultipleDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;

        // Expect the AddedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit AddedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add the delegatees
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify both delegatees were added
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "First delegatee should be added"
        );
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE_2),
            "Second delegatee should be added"
        );

        // Verify PKP is in both delegatees' lists
        uint256[] memory delegatedPkps1 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps1.length, 1, "Wrong number of delegated PKPs for first delegatee");
        assertEq(delegatedPkps1[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID for first delegatee");

        uint256[] memory delegatedPkps2 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE_2);
        assertEq(delegatedPkps2.length, 1, "Wrong number of delegated PKPs for second delegatee");
        assertEq(delegatedPkps2[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID for second delegatee");

        vm.stopPrank();
    }

    /// @notice Test adding delegatee with empty array
    function test_addEmptyDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](0);

        vm.expectRevert(PKPToolRegistryErrors.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test adding zero address as delegatee
    function test_addZeroAddressDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = address(0);

        vm.expectRevert(PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test non-owner adding delegatee
    function test_addDelegateeNonOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing a single delegatee
    function test_removeSingleDelegatee() public {
        vm.startPrank(deployer);

        // First add a delegatee
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Expect the RemovedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit RemovedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Remove the delegatee
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee was removed
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be removed"
        );

        // Verify PKP is removed from delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 0, "Delegated PKPs should be empty");

        vm.stopPrank();
    }

    /// @notice Test removing multiple delegatees
    function test_removeMultipleDelegatees() public {
        vm.startPrank(deployer);

        // First add multiple delegatees
        address[] memory delegatees = new address[](2);
        delegatees[0] = TEST_DELEGATEE;
        delegatees[1] = TEST_DELEGATEE_2;
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Expect the RemovedDelegatees event
        vm.expectEmit(true, false, false, true);
        emit RemovedDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Remove the delegatees
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify both delegatees were removed
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "First delegatee should be removed"
        );
        assertFalse(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE_2),
            "Second delegatee should be removed"
        );

        // Verify PKPs are removed from both delegatees' lists
        uint256[] memory delegatedPkps1 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps1.length, 0, "Delegated PKPs should be empty for first delegatee");

        uint256[] memory delegatedPkps2 = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE_2);
        assertEq(delegatedPkps2.length, 0, "Delegated PKPs should be empty for second delegatee");

        vm.stopPrank();
    }

    /// @notice Test removing delegatee with empty array
    function test_removeEmptyDelegatees() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](0);

        vm.expectRevert(PKPToolRegistryErrors.EmptyDelegatees.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing zero address as delegatee
    function test_removeZeroAddressDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = address(0);

        vm.expectRevert(PKPToolRegistryErrors.ZeroAddressCannotBeDelegatee.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test non-owner removing delegatee
    function test_removeDelegateeNonOwner() public {
        vm.startPrank(nonOwner);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test removing non-existent delegatee
    function test_removeNonExistentDelegatee() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Should not revert, just silently succeed
        PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        vm.stopPrank();
    }

    /// @notice Test delegatee with multiple PKPs
    function test_delegateeWithMultiplePKPs() public {
        vm.startPrank(deployer);

        // Add same delegatee to multiple PKPs
        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID_2, delegatees);

        // Verify delegatee is added to both PKPs
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID, TEST_DELEGATEE),
            "Delegatee should be added to first PKP"
        );
        assertTrue(
            PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(TEST_PKP_TOKEN_ID_2, TEST_DELEGATEE),
            "Delegatee should be added to second PKP"
        );

        // Verify both PKPs are in delegatee's list
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 2, "Wrong number of delegated PKPs");
        assertTrue(
            delegatedPkps[0] == TEST_PKP_TOKEN_ID || delegatedPkps[1] == TEST_PKP_TOKEN_ID,
            "First PKP should be in delegated list"
        );
        assertTrue(
            delegatedPkps[0] == TEST_PKP_TOKEN_ID_2 || delegatedPkps[1] == TEST_PKP_TOKEN_ID_2,
            "Second PKP should be in delegated list"
        );

        vm.stopPrank();
    }

    /// @notice Test adding same delegatee twice
    function test_addDelegateeTwice() public {
        vm.startPrank(deployer);

        address[] memory delegatees = new address[](1);
        delegatees[0] = TEST_DELEGATEE;

        // Add first time
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Add second time - should succeed but not duplicate
        PKPToolRegistryDelegateeFacet(address(diamond)).addDelegatees(TEST_PKP_TOKEN_ID, delegatees);

        // Verify delegatee is still added only once
        uint256[] memory delegatedPkps = PKPToolRegistryDelegateeFacet(address(diamond)).getDelegatedPkps(TEST_DELEGATEE);
        assertEq(delegatedPkps.length, 1, "Should only have one delegated PKP");
        assertEq(delegatedPkps[0], TEST_PKP_TOKEN_ID, "Wrong PKP token ID");

        vm.stopPrank();
    }
} 