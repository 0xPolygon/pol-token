// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {
    ProxyAdmin,
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {PolygonEcosystemToken} from "src/PolygonEcosystemToken.sol";
import {PolygonMigration} from "../../src/PolygonMigration.sol";

contract UpgradeEmissionManager is Script {
    using stdJson for string;

    function run() public {
        uint256 deployerPrivateKey = vm.promptSecretUint("Enter private key:");

        string memory input = vm.readFile("script/1.2.0/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address pmProxyAddress = input.readAddress(string.concat(chainIdSlug, ".polygonMigrationProxy"));
        address pmProxyAdmin = input.readAddress(string.concat(chainIdSlug, ".proxyAdmin"));
        address proxyAdminOwner = input.readAddress(string.concat(chainIdSlug, ".proxyAdminOwner"));
        address pol = input.readAddress(string.concat(chainIdSlug, ".polToken"));

        vm.startBroadcast(deployerPrivateKey);

        PolygonMigration pmProxy = PolygonMigration(pmProxyAddress);

        address matic = address(pmProxy.matic());

        PolygonMigration newEmImpl = new PolygonMigration(matic);

        vm.stopBroadcast();

        bytes memory payload = abi.encodeWithSelector(
            ProxyAdmin.upgrade.selector, ITransparentUpgradeableProxy(pmProxyAddress), address(newEmImpl)
        );

        console.log("newImpl: ", address(newEmImpl));
        console.log(
            "current Impl: ",
            ProxyAdmin(pmProxyAdmin).getProxyImplementation(ITransparentUpgradeableProxy(pmProxyAddress))
        );

        // test execution
        vm.prank(proxyAdminOwner);
        (bool success, /* bytes memory returnData */ ) = pmProxyAdmin.call(payload);

        assert(success);

        // check new implementation address
        assert(
            ProxyAdmin(pmProxyAdmin).getProxyImplementation(ITransparentUpgradeableProxy(pmProxyAddress))
                == address(newEmImpl)
        );

        // test migrateTo
        ERC20PresetMinterPauser maticContract = ERC20PresetMinterPauser(matic);
        address user = makeAddr("user");
        address migrateTo = makeAddr("migrateTo");
        uint256 amount = 1000;
        uint256 balanceBefore = maticContract.balanceOf(address(pmProxyAddress));

        vm.startPrank(matic);
        maticContract.transfer(user, amount);
        vm.startPrank(user);
        maticContract.approve(address(pmProxyAddress), amount);
        PolygonMigration(pmProxyAddress).migrateTo(migrateTo, amount);

        vm.assertEq(maticContract.balanceOf(user), 0);
        vm.assertEq(maticContract.balanceOf(address(pmProxyAddress)), balanceBefore + amount);
        vm.assertEq(PolygonEcosystemToken(pol).balanceOf(migrateTo), amount);

        console.log("Send this payload to: ", pmProxyAdmin);
        console.logBytes(payload);
    }
}
