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

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");

        string memory input = vm.readFile("script/1.2.0/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address emProxyAddress = input.readAddress(string.concat(chainIdSlug, ".emissionManagerProxy"));
        address emProxyAdmin = input.readAddress(string.concat(chainIdSlug, ".emProxyAdmin"));

        vm.startBroadcast(deployerPrivateKey);

        DefaultEmissionManager emProxy = DefaultEmissionManager(emProxyAddress);

        address migration = address(emProxy.migration());
        address stakeManager = emProxy.stakeManager();
        address treasury = emProxy.treasury();

        DefaultEmissionManager newEmImpl = new DefaultEmissionManager(migration, stakeManager, treasury);

        vm.stopBroadcast();

        bytes memory payload = abi.encodeWithSelector(
            ProxyAdmin.upgrade.selector,
            ITransparentUpgradeableProxy(address(emProxy)),
            address(newEmImpl)
        );

        console.log("Send this payload to: ", emProxyAdmin);
        console.logBytes(payload);
    }
}
