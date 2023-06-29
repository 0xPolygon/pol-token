// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Polygon} from "src/Polygon.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonTest is Test {
    Polygon public polygon;
    address public migration;
    address public treasury;
    address public hub;
    uint256 public constant ONE_YEAR = 31536000;

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        polygon = new Polygon(migration, hub, treasury);
    }

    function test_Deployment() external {
        assertEq(polygon.name(), "Polygon");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(polygon.balanceOf(hub), 0);
        assertEq(polygon.hub(), hub);
        assertEq(polygon.treasury(), treasury);
        assertEq(polygon.lastHubMint(), block.timestamp);
        assertEq(polygon.lastTreasuryMint(), block.timestamp);
    }

    function test_HubMint(uint256 delay) external {
        vm.assume(delay < ONE_YEAR);
        skip(delay);
        polygon.mintToHub();
        assertEq(polygon.lastHubMint(), block.timestamp);
        assertEq(polygon.balanceOf(hub), (delay * 10000000000e18) / (ONE_YEAR * 100));
    }

    function test_TreasuryMint(uint256 delay) external {
        vm.assume(delay < ONE_YEAR);
        skip(delay);
        polygon.mintToTreasury();
        assertEq(polygon.lastTreasuryMint(), block.timestamp);
        assertEq(polygon.balanceOf(treasury), (delay * 10000000000e18) / (ONE_YEAR * 100));
    }
}
