// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPolygon} from "src/interfaces/IPolygon.sol";
import {Polygon} from "src/Polygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PolygonTest is Test {
    Polygon public polygon;
    address public migration;
    address public treasury;
    address public hub;
    DefaultInflationManager public inflationManager;
    uint256 public constant ONE_YEAR = 31536000;

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        inflationManager = DefaultInflationManager(
            address(new TransparentUpgradeableProxy(address(new DefaultInflationManager()), msg.sender, ""))
        );
        polygon = new Polygon(migration, address(inflationManager), msg.sender);
        inflationManager.initialize(IPolygon(address(polygon)), hub, treasury, msg.sender);
    }

    function test_Deployment() external {
        assertEq(address(inflationManager.token()), address(polygon));
        assertEq(inflationManager.hub(), hub);
        assertEq(inflationManager.treasury(), treasury);
        assertEq(inflationManager.hubMintPerSecond(), 0);
        assertEq(inflationManager.treasuryMintPerSecond(), 0);
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(inflationManager.inflationModificationTimestamp(), block.timestamp + (365 days * 10));
        assertEq(inflationManager.owner(), msg.sender);
    }
}
