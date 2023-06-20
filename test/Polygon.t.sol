// SPDX-License-Identifier: MIT
pragma solidity 0.8.19;

import {Polygon} from "src/Polygon.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonTest is Test {
    Polygon public polygon;
    address public treasury;
    address public hub;

    function setUp() external {
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        polygon = new Polygon(treasury, hub);
    }

    function test_Deployment() external {
        assertEq(polygon.name(), "Polygon");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10100000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(hub), 100000000 * 10 ** 18);
        assertEq(polygon.hub(), hub);
        assertEq(polygon.lastMint(), block.timestamp);
    }
}
