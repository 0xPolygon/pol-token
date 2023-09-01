// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script} from "forge-std/Script.sol";

import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Polygon} from "../src/Polygon.sol";
import {DefaultInflationManager} from "../src/DefaultInflationManager.sol";
import {PolygonMigration} from "../src/PolygonMigration.sol";

contract Deploy is Script {
    uint256 public deployerPrivateKey;

    constructor() {
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
    }

    function run(address matic, address governance, address treasury, address stakeManager) public {
        vm.startBroadcast(deployerPrivateKey);

        address migrationImplementation = address(new PolygonMigration());

        address migrationProxy = address(
            new TransparentUpgradeableProxy(
                migrationImplementation,
                governance,
                abi.encodeCall(PolygonMigration.initialize, matic)
            )
        );

        address inflationManagerImplementation = address(new DefaultInflationManager());
        address inflationManagerProxy = address(
            new TransparentUpgradeableProxy(address(inflationManagerImplementation), governance, "")
        );

        Polygon polygonToken = new Polygon(migrationProxy, inflationManagerProxy);

        DefaultInflationManager(inflationManagerProxy).initialize(
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
