// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {ProxyAdmin, TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {PolygonEcosystemToken} from "../../src/PolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "../../src/DefaultEmissionManager.sol";
import {PolygonMigration} from "../../src/PolygonMigration.sol";

contract Deploy is Script {
    using stdJson for string;

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory input = vm.readFile("script/1.1.0/input.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address matic = input.readAddress(string.concat(chainIdSlug, ".matic"));
        address protocolCouncil = input.readAddress(string.concat(chainIdSlug, ".protocolCouncil"));
        address treasury = input.readAddress(string.concat(chainIdSlug, ".treasury"));
        address stakeManager = input.readAddress(string.concat(chainIdSlug, ".stakeManager"));
        address emergencyCouncil = input.readAddress(string.concat(chainIdSlug, ".emergencyCouncil"));

        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin admin = new ProxyAdmin();
        admin.transferOwnership(emergencyCouncil);

        address migrationImplementation = address(new PolygonMigration(matic));

        address migrationProxy = address(
            new TransparentUpgradeableProxy(
                migrationImplementation,
                address(admin),
                abi.encodeWithSelector(PolygonMigration.initialize.selector)
            )
        );

        address emissionManagerImplementation = address(
            new DefaultEmissionManager(migrationProxy, stakeManager, treasury)
        );
        address emissionManagerProxy = address(
            new TransparentUpgradeableProxy(address(emissionManagerImplementation), address(admin), "")
        );

        PolygonEcosystemToken polygonToken = new PolygonEcosystemToken(
            migrationProxy,
            emissionManagerProxy,
            protocolCouncil,
            emergencyCouncil
        );

        DefaultEmissionManager(emissionManagerProxy).initialize(address(polygonToken), protocolCouncil);

        PolygonMigration(migrationProxy).setPolygonToken(address(polygonToken));

        PolygonMigration(migrationProxy).transferOwnership(protocolCouncil); // governance needs to accept the ownership transfer

        vm.stopBroadcast();
    }
}
