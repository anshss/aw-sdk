// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {
    PKPToolPolicyRegistry,
    IPKPNFTFacet,
    EmptyIPFSCID,
    EmptyPolicy,
    EmptyVersion,
    NotPKPOwner,
    ToolNotFound
} from "../src/PKPToolPolicyRegistry.sol";

contract MockPKPNFT is IPKPNFTFacet {
    mapping(uint256 => address) private _owners;

    function setOwner(uint256 tokenId, address owner) external {
        _owners[tokenId] = owner;
    }

    function ownerOf(uint256 tokenId) external view returns (address) {
        return _owners[tokenId];
    }
}

contract PKPToolPolicyRegistryTest is Test {
    PKPToolPolicyRegistry public registry;
    MockPKPNFT public pkpNFT;
    uint256 public constant TOKEN_ID = 1;
    address public owner;
    string public constant IPFS_CID = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGx";
    bytes public constant POLICY = abi.encode(uint256(1e18), "ETH");
    string public constant VERSION = "1.0.0";

    event ToolPolicySet(
        uint256 indexed pkpTokenId,
        string ipfsCid,
        bytes policy,
        string version
    );

    event ToolPolicyRemoved(uint256 indexed pkpTokenId, string ipfsCid);

    event NewDelegatees(uint256 indexed pkpTokenId, address[] delegatees);
    event DelegateeRemoved(uint256 indexed pkpTokenId, address indexed delegatee);

    function setUp() public {
        pkpNFT = new MockPKPNFT();
        registry = new PKPToolPolicyRegistry(address(pkpNFT));
        owner = makeAddr("owner");
        pkpNFT.setOwner(TOKEN_ID, owner);
    }

    function test_SetToolPolicy() public {
        vm.startPrank(owner);

        vm.expectEmit(true, false, false, true);
        emit ToolPolicySet(TOKEN_ID, IPFS_CID, POLICY, VERSION);
        
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, POLICY, VERSION);

        (bytes memory storedPolicy, string memory storedVersion) = registry.getToolPolicy(TOKEN_ID, IPFS_CID);
        assertEq(storedPolicy, POLICY);
        assertEq(storedVersion, VERSION);

        vm.stopPrank();
    }

    function test_SetToolPolicy_UpdateExisting() public {
        vm.startPrank(owner);

        // Set initial policy
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, POLICY, VERSION);

        // Update with new policy
        bytes memory newPolicy = abi.encode(uint256(2e18), "USDC");
        string memory newVersion = "1.0.1";

        vm.expectEmit(true, false, false, true);
        emit ToolPolicySet(TOKEN_ID, IPFS_CID, newPolicy, newVersion);

        registry.setToolPolicy(TOKEN_ID, IPFS_CID, newPolicy, newVersion);

        (bytes memory storedPolicy, string memory storedVersion) = registry.getToolPolicy(TOKEN_ID, IPFS_CID);
        assertEq(storedPolicy, newPolicy);
        assertEq(storedVersion, newVersion);

        vm.stopPrank();
    }

    function test_RemoveToolPolicy() public {
        vm.startPrank(owner);

        // First set a policy
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, POLICY, VERSION);

        vm.expectEmit(true, false, false, true);
        emit ToolPolicyRemoved(TOKEN_ID, IPFS_CID);

        registry.removeToolPolicy(TOKEN_ID, IPFS_CID);

        // Verify policy is removed
        (bytes memory storedPolicy, string memory storedVersion) = registry.getToolPolicy(TOKEN_ID, IPFS_CID);
        assertEq(storedPolicy, "");
        assertEq(storedVersion, "");

        vm.stopPrank();
    }

    function test_GetRegisteredTools() public {
        vm.startPrank(owner);

        // Set multiple policies
        string memory cid1 = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGx";
        string memory cid2 = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGy";
        bytes memory policy1 = abi.encode(uint256(1e18), "ETH");
        bytes memory policy2 = abi.encode(uint256(2e18), "USDC");
        string memory version1 = "1.0.0";
        string memory version2 = "1.0.1";

        registry.setToolPolicy(TOKEN_ID, cid1, policy1, version1);
        registry.setToolPolicy(TOKEN_ID, cid2, policy2, version2);

        (
            string[] memory ipfsCids,
            bytes[] memory policyData,
            string[] memory versions
        ) = registry.getRegisteredTools(TOKEN_ID);

        assertEq(ipfsCids.length, 2);
        assertEq(policyData.length, 2);
        assertEq(versions.length, 2);

        // Verify first policy
        assertEq(ipfsCids[0], cid1);
        assertEq(policyData[0], policy1);
        assertEq(versions[0], version1);

        // Verify second policy
        assertEq(ipfsCids[1], cid2);
        assertEq(policyData[1], policy2);
        assertEq(versions[1], version2);

        vm.stopPrank();
    }

    function test_RevertWhen_NotOwner() public {
        address nonOwner = makeAddr("nonOwner");
        vm.startPrank(nonOwner);

        vm.expectRevert(NotPKPOwner.selector);
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, POLICY, VERSION);

        vm.expectRevert(NotPKPOwner.selector);
        registry.removeToolPolicy(TOKEN_ID, IPFS_CID);

        vm.stopPrank();
    }

    function test_RevertWhen_EmptyIPFSCID() public {
        vm.startPrank(owner);

        vm.expectRevert(EmptyIPFSCID.selector);
        registry.setToolPolicy(TOKEN_ID, "", POLICY, VERSION);

        vm.expectRevert(EmptyIPFSCID.selector);
        registry.removeToolPolicy(TOKEN_ID, "");

        vm.stopPrank();
    }

    function test_RevertWhen_EmptyPolicy() public {
        vm.startPrank(owner);

        vm.expectRevert(EmptyPolicy.selector);
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, "", VERSION);

        vm.stopPrank();
    }

    function test_RevertWhen_EmptyVersion() public {
        vm.startPrank(owner);

        vm.expectRevert(EmptyVersion.selector);
        registry.setToolPolicy(TOKEN_ID, IPFS_CID, POLICY, "");

        vm.stopPrank();
    }

    function test_RevertWhen_ToolNotFound() public {
        vm.startPrank(owner);

        vm.expectRevert(abi.encodeWithSelector(ToolNotFound.selector, IPFS_CID));
        registry.removeToolPolicy(TOKEN_ID, IPFS_CID);

        vm.stopPrank();
    }

    function test_RemoveToolPolicy_WithMultipleTools() public {
        vm.startPrank(owner);

        // Set multiple policies
        string memory cid1 = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGx";
        string memory cid2 = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGy";
        string memory cid3 = "QmZ4tDuvesekSs4qM5ZBKpXiZGun7S2CYtEZRB3DYXkjGz";
        
        registry.setToolPolicy(TOKEN_ID, cid1, POLICY, VERSION);
        registry.setToolPolicy(TOKEN_ID, cid2, POLICY, VERSION);
        registry.setToolPolicy(TOKEN_ID, cid3, POLICY, VERSION);

        // Remove middle policy
        registry.removeToolPolicy(TOKEN_ID, cid2);

        (
            string[] memory ipfsCids,
            bytes[] memory policyData,
            string[] memory versions
        ) = registry.getRegisteredTools(TOKEN_ID);

        // Verify length
        assertEq(ipfsCids.length, 2);
        assertEq(policyData.length, 2);
        assertEq(versions.length, 2);

        // Verify remaining policies
        assertEq(ipfsCids[0], cid1);
        assertEq(ipfsCids[1], cid3);
        assertEq(policyData[0], POLICY);
        assertEq(policyData[1], POLICY);
        assertEq(versions[0], VERSION);
        assertEq(versions[1], VERSION);

        vm.stopPrank();
    }

    function test_AddDelegatee() public {
        vm.startPrank(owner);
        address delegatee = makeAddr("delegatee");

        address[] memory expectedDelegatees = new address[](1);
        expectedDelegatees[0] = delegatee;

        vm.expectEmit(true, true, false, true);
        emit NewDelegatees(TOKEN_ID, expectedDelegatees);

        registry.addDelegatee(TOKEN_ID, delegatee);

        assertTrue(registry.isDelegateeOf(TOKEN_ID, delegatee));
        address[] memory storedDelegatees = registry.getDelegatees(TOKEN_ID);
        assertEq(storedDelegatees.length, 1);
        assertEq(storedDelegatees[0], delegatee);

        vm.stopPrank();
    }

    function test_RemoveDelegatee() public {
        vm.startPrank(owner);
        address delegatee = makeAddr("delegatee");

        // First add a delegatee
        registry.addDelegatee(TOKEN_ID, delegatee);

        vm.expectEmit(true, true, false, true);
        emit DelegateeRemoved(TOKEN_ID, delegatee);

        registry.removeDelegatee(TOKEN_ID, delegatee);

        assertFalse(registry.isDelegateeOf(TOKEN_ID, delegatee));
        address[] memory storedDelegatees = registry.getDelegatees(TOKEN_ID);
        assertEq(storedDelegatees.length, 0);

        vm.stopPrank();
    }

    function test_BatchAddDelegatees() public {
        vm.startPrank(owner);
        address[] memory delegatees = new address[](2);
        delegatees[0] = makeAddr("delegatee1");
        delegatees[1] = makeAddr("delegatee2");

        vm.expectEmit(true, false, false, true);
        emit NewDelegatees(TOKEN_ID, delegatees);

        registry.batchAddDelegatees(TOKEN_ID, delegatees);

        assertTrue(registry.isDelegateeOf(TOKEN_ID, delegatees[0]));
        assertTrue(registry.isDelegateeOf(TOKEN_ID, delegatees[1]));
        address[] memory storedDelegatees = registry.getDelegatees(TOKEN_ID);
        assertEq(storedDelegatees.length, 2);
        assertEq(storedDelegatees[0], delegatees[0]);
        assertEq(storedDelegatees[1], delegatees[1]);

        vm.stopPrank();
    }

    function test_BatchRemoveDelegatees() public {
        vm.startPrank(owner);
        address[] memory delegatees = new address[](2);
        delegatees[0] = makeAddr("delegatee1");
        delegatees[1] = makeAddr("delegatee2");

        // First add delegatees
        registry.batchAddDelegatees(TOKEN_ID, delegatees);

        // Expect removal events
        vm.expectEmit(true, true, false, true);
        emit DelegateeRemoved(TOKEN_ID, delegatees[0]);
        vm.expectEmit(true, true, false, true);
        emit DelegateeRemoved(TOKEN_ID, delegatees[1]);

        registry.batchRemoveDelegatees(TOKEN_ID, delegatees);

        assertFalse(registry.isDelegateeOf(TOKEN_ID, delegatees[0]));
        assertFalse(registry.isDelegateeOf(TOKEN_ID, delegatees[1]));
        address[] memory storedDelegatees = registry.getDelegatees(TOKEN_ID);
        assertEq(storedDelegatees.length, 0);

        vm.stopPrank();
    }
}
