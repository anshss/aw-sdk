// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import "../script/DeployPKPToolRegistry.s.sol";
import "../src/PKPToolRegistry.sol";
import "../src/facets/PKPToolRegistryBlanketParameterFacet.sol";
import "../src/facets/PKPToolRegistryToolFacet.sol";
import "../src/libraries/PKPToolRegistryErrors.sol";
import "../src/libraries/PKPToolRegistryParameterEvents.sol";
import "./mocks/MockPKPNFT.sol";

contract PKPToolRegistryBlanketParameterFacetTest is Test {
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
    string constant TEST_TOOL_CID = "QmTEST";
    string constant TEST_PARAM_NAME = "maxAmount";
    string constant TEST_PARAM_NAME_2 = "minAmount";
    bytes constant TEST_PARAM_VALUE = abi.encode(1000);
    bytes constant TEST_PARAM_VALUE_2 = abi.encode(100);

    // Events to test
    event BlanketPolicyParametersSet(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames,
        bytes[] parameterValues
    );
    event BlanketPolicyParametersRemoved(
        uint256 indexed pkpTokenId,
        string toolIpfsCid,
        string[] parameterNames
    );

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

        // Register a tool for testing
        vm.startPrank(deployer);
        string[] memory toolIpfsCids = new string[](1);
        toolIpfsCids[0] = TEST_TOOL_CID;
        PKPToolRegistryToolFacet(address(diamond)).registerTools(TEST_PKP_TOKEN_ID, toolIpfsCids, true);
        vm.stopPrank();
    }

    /// @notice Test setting a single parameter
    function test_setParameter() public {
        vm.startPrank(deployer);

        string[] memory parameterNames = new string[](1);
        parameterNames[0] = TEST_PARAM_NAME;
        bytes[] memory parameterValues = new bytes[](1);
        parameterValues[0] = TEST_PARAM_VALUE;

        // Expect the BlanketPolicyParametersSet event
        vm.expectEmit(true, false, false, true);
        emit BlanketPolicyParametersSet(TEST_PKP_TOKEN_ID, TEST_TOOL_CID, parameterNames, parameterValues);

        // Set the parameter
        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            parameterValues
        );

        // Verify parameter was set
        string[] memory storedParamNames = PKPToolRegistryBlanketParameterFacet(address(diamond)).getBlanketToolPolicyParameterNames(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID
        );
        assertEq(storedParamNames.length, 1, "Wrong number of parameter names");
        assertEq(storedParamNames[0], TEST_PARAM_NAME, "Wrong parameter name");

        vm.stopPrank();
    }

    /// @notice Test setting multiple parameters
    function test_setMultipleParameters() public {
        vm.startPrank(deployer);

        string[] memory parameterNames = new string[](2);
        parameterNames[0] = TEST_PARAM_NAME;
        parameterNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory parameterValues = new bytes[](2);
        parameterValues[0] = TEST_PARAM_VALUE;
        parameterValues[1] = TEST_PARAM_VALUE_2;

        // Expect the BlanketPolicyParametersSet event
        vm.expectEmit(true, false, false, true);
        emit BlanketPolicyParametersSet(TEST_PKP_TOKEN_ID, TEST_TOOL_CID, parameterNames, parameterValues);

        // Set the parameters
        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            parameterValues
        );

        // Verify parameters were set
        string[] memory storedParamNames = PKPToolRegistryBlanketParameterFacet(address(diamond)).getBlanketToolPolicyParameterNames(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID
        );
        assertEq(storedParamNames.length, 2, "Wrong number of parameter names");
        assertTrue(
            (keccak256(bytes(storedParamNames[0])) == keccak256(bytes(TEST_PARAM_NAME)) && 
             keccak256(bytes(storedParamNames[1])) == keccak256(bytes(TEST_PARAM_NAME_2))) ||
            (keccak256(bytes(storedParamNames[0])) == keccak256(bytes(TEST_PARAM_NAME_2)) && 
             keccak256(bytes(storedParamNames[1])) == keccak256(bytes(TEST_PARAM_NAME))),
            "Wrong parameter names"
        );

        vm.stopPrank();
    }

    /// @notice Test removing parameters
    function test_removeParameters() public {
        vm.startPrank(deployer);

        // First set some parameters
        string[] memory parameterNames = new string[](2);
        parameterNames[0] = TEST_PARAM_NAME;
        parameterNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory parameterValues = new bytes[](2);
        parameterValues[0] = TEST_PARAM_VALUE;
        parameterValues[1] = TEST_PARAM_VALUE_2;

        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            parameterValues
        );

        // Remove one parameter
        string[] memory paramsToRemove = new string[](1);
        paramsToRemove[0] = TEST_PARAM_NAME;

        // Expect the BlanketPolicyParametersRemoved event
        vm.expectEmit(true, false, false, true);
        emit BlanketPolicyParametersRemoved(TEST_PKP_TOKEN_ID, TEST_TOOL_CID, paramsToRemove);

        // Remove the parameter
        PKPToolRegistryBlanketParameterFacet(address(diamond)).removeBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            paramsToRemove
        );

        // Verify parameter was removed
        string[] memory storedParamNames = PKPToolRegistryBlanketParameterFacet(address(diamond)).getBlanketToolPolicyParameterNames(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID
        );
        assertEq(storedParamNames.length, 1, "Wrong number of parameter names");
        assertEq(storedParamNames[0], TEST_PARAM_NAME_2, "Wrong remaining parameter");

        vm.stopPrank();
    }

    /// @notice Test getting parameters
    function test_getParameters() public {
        vm.startPrank(deployer);

        // First set some parameters
        string[] memory parameterNames = new string[](2);
        parameterNames[0] = TEST_PARAM_NAME;
        parameterNames[1] = TEST_PARAM_NAME_2;
        bytes[] memory parameterValues = new bytes[](2);
        parameterValues[0] = TEST_PARAM_VALUE;
        parameterValues[1] = TEST_PARAM_VALUE_2;

        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            parameterValues
        );

        // Get parameter names
        string[] memory storedParamNames = PKPToolRegistryBlanketParameterFacet(address(diamond)).getBlanketToolPolicyParameterNames(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID
        );
        assertEq(storedParamNames.length, 2, "Wrong number of parameter names");
        assertTrue(
            (keccak256(bytes(storedParamNames[0])) == keccak256(bytes(TEST_PARAM_NAME)) && 
             keccak256(bytes(storedParamNames[1])) == keccak256(bytes(TEST_PARAM_NAME_2))) ||
            (keccak256(bytes(storedParamNames[0])) == keccak256(bytes(TEST_PARAM_NAME_2)) && 
             keccak256(bytes(storedParamNames[1])) == keccak256(bytes(TEST_PARAM_NAME))),
            "Wrong parameter names"
        );

        // Get parameter values
        bytes[] memory storedParamValues = PKPToolRegistryBlanketParameterFacet(address(diamond)).getBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames
        );
        assertEq(storedParamValues.length, 2, "Wrong number of parameter values");
        assertEq(storedParamValues[0], TEST_PARAM_VALUE, "Wrong first parameter value");
        assertEq(storedParamValues[1], TEST_PARAM_VALUE_2, "Wrong second parameter value");

        vm.stopPrank();
    }

    /// @notice Test error cases
    function test_errorCases() public {
        vm.startPrank(deployer);

        string[] memory parameterNames = new string[](1);
        parameterNames[0] = TEST_PARAM_NAME;
        bytes[] memory parameterValues = new bytes[](1);
        parameterValues[0] = TEST_PARAM_VALUE;

        // Test non-owner cannot set parameters
        vm.stopPrank();
        vm.startPrank(nonOwner);
        vm.expectRevert(PKPToolRegistryErrors.NotPKPOwner.selector);
        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            parameterValues
        );
        vm.stopPrank();
        vm.startPrank(deployer);

        // Test array length mismatch
        bytes[] memory mismatchedValues = new bytes[](2);
        mismatchedValues[0] = TEST_PARAM_VALUE;
        mismatchedValues[1] = TEST_PARAM_VALUE_2;
        vm.expectRevert(PKPToolRegistryErrors.ArrayLengthMismatch.selector);
        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            TEST_TOOL_CID,
            parameterNames,
            mismatchedValues
        );

        // Test cannot set parameters for non-existent tool
        vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolNotFound.selector, "QmNONEXISTENT"));
        PKPToolRegistryBlanketParameterFacet(address(diamond)).setBlanketToolPolicyParameters(
            TEST_PKP_TOKEN_ID,
            "QmNONEXISTENT",
            parameterNames,
            parameterValues
        );

        vm.stopPrank();
    }
} 