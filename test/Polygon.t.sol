// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Polygon} from "src/Polygon.sol";
import {IPolygon} from "src/interfaces/IPolygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonTest is Test {
    Polygon public polygon;
    address public matic;
    address public migration;
    address public treasury;
    address public stakeManager;
    DefaultInflationManager public inflationManager;

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        matic = makeAddr("matic");
        inflationManager = DefaultInflationManager(
            address(
                new TransparentUpgradeableProxy(
                    address(new DefaultInflationManager()),
                    msg.sender,
                    ""
                )
            )
        );
        polygon = new Polygon(migration, address(inflationManager));
        inflationManager.initialize(
            address(polygon),
            migration,
            stakeManager,
            treasury,
            msg.sender
        );
    }

    function test_Deployment() external {
        assertEq(polygon.name(), "Polygon");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.inflationManager(), address(inflationManager));
    }

    function test_InvalidDeployment() external {
        Polygon token;
        vm.expectRevert(IPolygon.InvalidAddress.selector);
        token = new Polygon(makeAddr("migration"), address(0));
        vm.expectRevert(IPolygon.InvalidAddress.selector);
        token = new Polygon(address(0), makeAddr("inflationManager"));
        vm.expectRevert(IPolygon.InvalidAddress.selector);
        token = new Polygon(address(0), address(0));
    }

    function testRevert_Mint(
        address user,
        address to,
        uint256 amount
    ) external {
        vm.assume(user != address(inflationManager));
        vm.startPrank(user);
        vm.expectRevert(IPolygon.OnlyInflationManager.selector);
        polygon.mint(to, amount);
    }

    function test_Mint(address to, uint256 amount) external {
        vm.assume(
            to != address(0) &&
                amount <= 10000000000 * 10 ** 18 &&
                to != migration
        );
        vm.startPrank(address(inflationManager));
        polygon.mint(to, amount);

        assertEq(polygon.balanceOf(to), amount);
    }
}
