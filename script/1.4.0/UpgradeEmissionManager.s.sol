// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {
    ProxyAdmin,
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {DefaultEmissionManager} from "../../src/DefaultEmissionManager.sol";

contract UpgradeEmissionManager is Script {
    using stdJson for string;

    uint256 deployerPrivateKey = uint256(uint160(address(this))); // default placeholder for tests

    string input = vm.readFile("script/1.4.0/input.json");
    string chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
    address emProxyAddress = input.readAddress(string.concat(chainIdSlug, ".emissionManagerProxy"));
    address emProxyAdmin = input.readAddress(string.concat(chainIdSlug, ".emProxyAdmin"));

    DefaultEmissionManager emProxy = DefaultEmissionManager(emProxyAddress);

    function run() public {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        bytes memory payload = upgradeEM();

        console.log("Send this payload to: ", emProxyAdmin);
        console.logBytes(payload);
    }

    function upgradeEM() public returns (bytes memory) {
        vm.startBroadcast(deployerPrivateKey);

        address migration = address(emProxy.migration());
        address stakeManager = emProxy.stakeManager();
        address treasury = emProxy.treasury();

        DefaultEmissionManager newEmImpl = new DefaultEmissionManager(migration, stakeManager, treasury);

        vm.stopBroadcast();
        bytes memory data = abi.encodeCall(DefaultEmissionManager.reinitialize, ());
        bytes memory payload = abi.encodeWithSelector(
            ProxyAdmin.upgradeAndCall.selector, ITransparentUpgradeableProxy(address(emProxy)), address(newEmImpl), data
        );

        return payload;
    }
}
