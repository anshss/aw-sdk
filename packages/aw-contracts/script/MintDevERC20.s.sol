// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DevERC20.sol";

contract MintDevERC20Script is Script {
    function run() external {
        // Get environment variables
        uint256 deployerPrivateKey = vm.envUint("DEVERC20_DEPLOYER_PRIVATE_KEY");
        address recipient = vm.envAddress("DEVERC20_MINT_RECIPIENT");
        uint256 amount = vm.envUint("DEVERC20_MINT_AMOUNT");
        address tokenAddress = vm.envAddress("DEVERC20_CONTRACT_ADDRESS");

        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Get the token contract
        DevERC20 token = DevERC20(tokenAddress);

        // Mint tokens
        token.mint(recipient, amount);

        vm.stopBroadcast();

        // Log the minting details
        console.log("Minted", amount, "tokens for", recipient);
        console.log("Token balance:", token.balanceOf(recipient));
    }
} 