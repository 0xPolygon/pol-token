// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Polygon} from "src/Polygon.sol";
import {Test} from "forge-std/Test.sol";

// contract PolygonTest is Test {
//     Polygon private polygon;
//     address private treasury;
//     address private hub;
//     uint256 private constant ONE_YEAR = 31536000;

//     function setUp() external {
//         treasury = makeAddr("treasury");
//         hub = makeAddr("hub");
//         polygon = new Polygon(treasury, hub);
//     }

//     function test_Deployment() external {
//         assertEq(polygon.name(), "Polygon");
//         assertEq(polygon.symbol(), "POL");
//         assertEq(polygon.decimals(), 18);
//         assertEq(polygon.totalSupply(), 10100000000 * 10 ** 18);
//         assertEq(polygon.balanceOf(treasury), 10000000000 * 10 ** 18);
//         assertEq(polygon.balanceOf(hub), 100000000 * 10 ** 18);
//         assertEq(polygon.hub(), hub);
//         assertEq(polygon.lastMint(), block.timestamp);
//     }

//     function test_RevertMintBeforeTime(uint256 delay) external {
//         vm.assume(delay < ONE_YEAR);
//         vm.warp(block.timestamp + delay);
//         vm.expectRevert("Polygon: minting not allowed yet");
//         polygon.mint();
//     }

//     function test_mint(uint224 delay) external {
//         vm.assume(delay >= ONE_YEAR);
//         vm.warp(block.timestamp + delay);
//         uint256 timestamp = polygon.lastMint();
//         polygon.mint();
//         assertEq(polygon.lastMint(), timestamp + ONE_YEAR);
//         assertEq(polygon.balanceOf(hub), 201000000 * 10 ** 18);
//     }
// }
