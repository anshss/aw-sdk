/// @notice Test error cases
function test_errorCases() public {
    vm.startPrank(deployer);
    
    // Test duplicate tool registration
    string[] memory toolIpfsCids = new string[](1);
    toolIpfsCids[0] = "error-test-tool";
    
    PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids);
    vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolAlreadyExists.selector, "error-test-tool"));
    PKPToolRegistryToolFacet(address(diamond)).registerTools(1, toolIpfsCids);
    
    // Test policy setting for non-existent tool
    string[] memory nonExistentTools = new string[](1);
    nonExistentTools[0] = "non-existent-tool";
    string[] memory policyIpfsCids = new string[](1);
    policyIpfsCids[0] = "error-test-policy";
    
    address delegatee = makeAddr("error-test-delegatee");
    address[] memory delegatees = new address[](1);
    delegatees[0] = delegatee;
    
    vm.expectRevert(abi.encodeWithSelector(PKPToolRegistryErrors.ToolNotFound.selector, "non-existent-tool"));
    PKPToolRegistryPolicyFacet(address(diamond)).setCustomToolPoliciesForDelegatees(
        1,
        nonExistentTools,
        delegatees,
        policyIpfsCids,
        true // enable policies
    );
    
    // Test removing non-existent delegatee
    // First verify the delegatee doesn't exist
    address nonExistentDelegateePure = makeAddr("non-existent-delegatee-pure");
    assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should not exist");
    
    // Now try to remove it
    address[] memory nonExistentDelegateesArray = new address[](1);
    nonExistentDelegateesArray[0] = nonExistentDelegateePure;
    
    // Since the delegatee doesn't exist, removing it should have no effect
    PKPToolRegistryDelegateeFacet(address(diamond)).removeDelegatees(1, nonExistentDelegateesArray);
    
    // Verify it still doesn't exist
    assertFalse(PKPToolRegistryDelegateeFacet(address(diamond)).isPkpDelegatee(1, nonExistentDelegateePure), "Delegatee should still not exist");
    
    vm.stopPrank();
}