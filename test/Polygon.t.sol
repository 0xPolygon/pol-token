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

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        inflationManager = DefaultInflationManager(
            address(new TransparentUpgradeableProxy(address(new DefaultInflationManager()), msg.sender, ""))
        );
        polygon = new Polygon(migration, address(inflationManager));
        inflationManager.initialize(IPolygon(address(polygon)), hub, treasury, msg.sender);
    }

    function test_Deployment() external {
        assertEq(polygon.name(), "Polygon");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(polygon.balanceOf(hub), 0);
        assertEq(polygon.inflationManager(), address(inflationManager));
    }

    function testRevert_Mint(address user, address to, uint256 amount) external {
        vm.assume(user != address(inflationManager));
        vm.startPrank(user);
        vm.expectRevert("Polygon: only inflation manager can mint");
        polygon.mint(to, amount);
    }

    function test_Mint(address to, uint256 amount) external {
        vm.assume(to != address(0) && amount <= 10000000000 * 10 ** 18 && to != migration);
        vm.startPrank(address(inflationManager));
        polygon.mint(to, amount);

        assertEq(polygon.balanceOf(to), amount);
    }
}
