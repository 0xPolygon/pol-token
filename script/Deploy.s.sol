// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";

import {ProxyAdmin, TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {PolygonEcosystemToken} from "../src/PolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "../src/DefaultEmissionManager.sol";
import {PolygonMigration} from "../src/PolygonMigration.sol";

contract Deploy is Script {
    uint256 public deployerPrivateKey;

    constructor() {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    function run(address matic, address governance, address treasury, address stakeManager) public {
        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin admin = new ProxyAdmin();
        admin.transferOwnership(governance);

        address migrationImplementation = address(new PolygonMigration());

        address migrationProxy = address(
            new TransparentUpgradeableProxy(
                migrationImplementation,
                address(admin),
                abi.encodeCall(PolygonMigration.initialize, matic)
            )
        );

        address emissionManagerImplementation = address(new DefaultEmissionManager());
        address emissionManagerProxy = address(
            new TransparentUpgradeableProxy(address(emissionManagerImplementation), address(admin), "")
        );

        PolygonEcosystemToken polygonToken = new PolygonEcosystemToken(migrationProxy, emissionManagerProxy);

        DefaultEmissionManager(emissionManagerProxy).initialize(
            address(polygonToken),
            migrationProxy,
            stakeManager,
            treasury,
            governance
        );

        PolygonMigration(migrationProxy).setPolygonToken(address(polygonToken));

        PolygonMigration(migrationProxy).transferOwnership(governance); // governance needs to accept the ownership transfer

        vm.stopBroadcast();
    }
}
