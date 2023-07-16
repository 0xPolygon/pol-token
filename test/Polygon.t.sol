// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Polygon} from "src/Polygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PolygonTest is Test {
    // Polygon public polygon;
    // address public migration;
    // address public treasury;
    // address public hub;
    // uint256 public constant ONE_YEAR = 31536000;

    // function setUp() external {
    //     migration = makeAddr("migration");
    //     treasury = makeAddr("treasury");
    //     hub = makeAddr("hub");
    //     inflationManager = new InflationManager();
    //     polygon = new Polygon(migration, hub, treasury, msg.sender);
    // }

    // function test_Deployment() external {
    //     assertEq(polygon.name(), "Polygon");
    //     assertEq(polygon.symbol(), "POL");
    //     assertEq(polygon.decimals(), 18);
    //     assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
    //     assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
    //     assertEq(polygon.balanceOf(treasury), 0);
    //     assertEq(polygon.balanceOf(hub), 0);
    //     assertEq(polygon.hub(), hub);
    //     assertEq(polygon.treasury(), treasury);
    //     assertEq(polygon.owner(), msg.sender);
    //     assertEq(
    //         polygon.nextSupplyIncreaseTimestamp(),
    //         block.timestamp + ONE_YEAR
    //     );
    //     assertEq(polygon.lastHubMint(), block.timestamp);
    //     assertEq(polygon.lastTreasuryMint(), block.timestamp);
    // }

    // function test_HubMint(uint256 delay) external {
    //     vm.assume(delay < ONE_YEAR);
    //     skip(delay);
    //     polygon.mintToHub();
    //     assertEq(polygon.lastHubMint(), block.timestamp);
    //     assertEq(
    //         polygon.balanceOf(hub),
    //         (delay * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    // }

    // function test_HubMintExceedingYearly(uint128 delay) external {
    //     vm.assume(delay >= ONE_YEAR);
    //     skip(delay);
    //     uint256 _nextSupplyIncreaseTimestamp = polygon
    //         .nextSupplyIncreaseTimestamp();
    //     polygon.mintToHub();
    //     assertEq(polygon.previousSupply(), (10000000000e18 * 102) / 100);
    //     assertEq(polygon.lastHubMint(), _nextSupplyIncreaseTimestamp);
    //     assertEq(polygon.lastTreasuryMint(), _nextSupplyIncreaseTimestamp);
    //     assertEq(
    //         polygon.nextSupplyIncreaseTimestamp(),
    //         _nextSupplyIncreaseTimestamp + ONE_YEAR
    //     );
    //     assertEq(
    //         polygon.balanceOf(hub),
    //         (ONE_YEAR * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    //     assertEq(
    //         polygon.balanceOf(treasury),
    //         (ONE_YEAR * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    // }

    // function test_TreasuryMint(uint256 delay) external {
    //     vm.assume(delay < ONE_YEAR);
    //     skip(delay);
    //     polygon.mintToTreasury();
    //     assertEq(polygon.lastTreasuryMint(), block.timestamp);
    //     assertEq(
    //         polygon.balanceOf(treasury),
    //         (delay * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    // }

    // function test_TreasuryMintExceedingYearly(uint128 delay) external {
    //     vm.assume(delay >= ONE_YEAR);
    //     skip(delay);
    //     uint256 _nextSupplyIncreaseTimestamp = polygon
    //         .nextSupplyIncreaseTimestamp();
    //     polygon.mintToTreasury();
    //     assertEq(polygon.previousSupply(), (10000000000e18 * 102) / 100);
    //     assertEq(polygon.lastHubMint(), _nextSupplyIncreaseTimestamp);
    //     assertEq(polygon.lastTreasuryMint(), _nextSupplyIncreaseTimestamp);
    //     assertEq(
    //         polygon.nextSupplyIncreaseTimestamp(),
    //         _nextSupplyIncreaseTimestamp + ONE_YEAR
    //     );
    //     assertEq(
    //         polygon.balanceOf(hub),
    //         (ONE_YEAR * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    //     assertEq(
    //         polygon.balanceOf(treasury),
    //         (ONE_YEAR * 10000000000e18) / (ONE_YEAR * 100)
    //     );
    // }

    // function testRevert_updateHubInflationRateTooEarly(
    //     uint64 time,
    //     uint256 rate
    // ) external {
    //     vm.assume(
    //         time < polygon.inflationRateModificationTimestamp() && rate < 1e3
    //     );
    //     vm.warp(time);
    //     vm.startPrank(polygon.owner());
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Polygon.Invalid.selector,
    //             "inflation rate cannot be modified yet"
    //         )
    //     );
    //     polygon.updateHubInflation(rate);
    // }

    // function testRevert_updateHubInflationRateInvalid(
    //     uint64 time,
    //     uint256 rate
    // ) external {
    //     vm.assume(
    //         time >= polygon.inflationRateModificationTimestamp() && rate >= 1e3
    //     );
    //     vm.warp(time);
    //     vm.startPrank(polygon.owner());
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Polygon.Invalid.selector,
    //             "inflation rate must be less than previous"
    //         )
    //     );
    //     polygon.updateHubInflation(rate);
    // }

    // function testRevert_updateTreasuryInflationRateTooEarly(
    //     uint64 time,
    //     uint256 rate
    // ) external {
    //     vm.assume(
    //         time < polygon.inflationRateModificationTimestamp() && rate < 1e3
    //     );
    //     vm.warp(time);
    //     vm.startPrank(polygon.owner());
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Polygon.Invalid.selector,
    //             "inflation rate cannot be modified yet"
    //         )
    //     );
    //     polygon.updateTreasuryInflation(rate);
    // }

    // function testRevert_updateTreasuryInflationRateInvalid(
    //     uint64 time,
    //     uint256 rate
    // ) external {
    //     vm.assume(
    //         time >= polygon.inflationRateModificationTimestamp() && rate >= 1e3
    //     );
    //     vm.warp(time);
    //     vm.startPrank(polygon.owner());
    //     vm.expectRevert(
    //         abi.encodeWithSelector(
    //             Polygon.Invalid.selector,
    //             "inflation rate must be less than previous"
    //         )
    //     );
    //     polygon.updateTreasuryInflation(rate);
    // }
}
