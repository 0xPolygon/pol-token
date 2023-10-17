// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {ProxyAdmin, TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {DefaultEmissionManager} from "../../src/DefaultEmissionManager.sol";

contract Deploy is Script {
    using stdJson for string;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory input = vm.readFile("scripts/1.1.0/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address migrationProxy = input.readAddress(string.concat(chainIdSlug, ".migrationProxy"));
        address stakeManager = input.readAddress(string.concat(chainIdSlug, ".stakeManager"));
        address treasury = input.readAddress(string.concat(chainIdSlug, ".treasury"));
        vm.startBroadcast(deployerPrivateKey);

        new DefaultEmissionManager(migrationProxy, stakeManager, treasury);

        vm.stopBroadcast();
    }
}
