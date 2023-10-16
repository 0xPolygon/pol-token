// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {ProxyAdmin, TransparentUpgradeableProxy, ITransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {DefaultEmissionManager} from "../../src/DefaultEmissionManager.sol";

contract Deploy is Script {
    using stdJson for string;

    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";
    uint256 public deployerPrivateKey;

    constructor() {
        deployerPrivateKey = vm.envOr({name: "PRIVATE_KEY", defaultValue: uint256(0)});
        if (deployerPrivateKey == 0) {
            (, deployerPrivateKey) = deriveRememberKey({mnemonic: TEST_MNEMONIC, index: 0});
        }
    }

    function run() public {
        string memory input = vm.readFile("scripts/1.1.0/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        ITransparentUpgradeableProxy emissionProxy = ITransparentUpgradeableProxy(
            input.readAddress(string.concat(chainIdSlug, ".emissionProxy"))
        );
        address proxyAdmin = input.readAddress(string.concat(chainIdSlug, ".proxyAdmin"));
        address migrationProxy = input.readAddress(string.concat(chainIdSlug, ".migrationProxy"));
        address stakeManager = input.readAddress(string.concat(chainIdSlug, ".stakeManager"));
        address treasury = input.readAddress(string.concat(chainIdSlug, ".treasury"));
        vm.startBroadcast(deployerPrivateKey);
        ProxyAdmin admin = ProxyAdmin(proxyAdmin);

        address emissionManagerImplementationUpgrade = address(
            new DefaultEmissionManager(migrationProxy, stakeManager, treasury)
        );

        admin.upgrade(emissionProxy, emissionManagerImplementationUpgrade);

        vm.stopBroadcast();
    }
}
