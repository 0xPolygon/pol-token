// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IPolygon} from "src/interfaces/IPolygon.sol";
import {Polygon} from "src/Polygon.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {
    IERC20,
    ERC20PresetMinterPauser
} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract PolygonMigrationTest is Test {
    ERC20PresetMinterPauser public matic;
    Polygon public polygon;
    PolygonMigration public migration;
    address public treasury;
    address public hub;
    address public inflationManager;
    address public governance;

    function setUp() external {
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        inflationManager = makeAddr("inflationManager");
        governance = makeAddr("governance");
        matic = new ERC20PresetMinterPauser("Matic Token", "MATIC");
        migration =
            new PolygonMigration(IERC20(0xF62849F9A0B5Bf2913b396098F7c7019b51A820a), IERC20(address(matic)), governance);
        polygon = new Polygon(address(migration), address(inflationManager), msg.sender);
    }

    function test_Deployment() external {
        assertEq(address(migration.polygon()), address(polygon));
        assertEq(address(migration.matic()), address(matic));
        assertEq(migration.releaseTimestamp(), block.timestamp + (365 days * 4));
        assertEq(migration.owner(), governance);
    }

    function test_Migrate(address user, uint256 amount) external {
        vm.assume(amount <= 10000000000 * 10 ** 18 && user != address(0));
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(0x000000000000000000000000000000000000dEaD), amount);
        assertEq(polygon.balanceOf(user), amount);
    }

    function testRevert_UpdateReleaseTimestampOnlyGovernance(address user, uint256 timestamp) external {
        vm.assume(timestamp >= block.timestamp && user != governance);
        vm.expectRevert("Ownable: caller is not the owner");
        migration.updateReleaseTimestamp(timestamp);
    }

    function testRevert_UpdateReleaseTimestampTooEarly(uint256 timestamp) external {
        vm.assume(timestamp < block.timestamp);
        vm.startPrank(governance);
        vm.expectRevert("PolygonMigration: invalid timestamp");
        migration.updateReleaseTimestamp(timestamp);
    }

    function test_UpdateReleaseTimestamp(uint256 timestamp) external {
        vm.assume(timestamp >= block.timestamp);
        vm.startPrank(governance);
        migration.updateReleaseTimestamp(timestamp);

        assertEq(migration.releaseTimestamp(), timestamp);
    }

    function testRevert_ReleaseOnlyGovernance() external {
        vm.expectRevert("Ownable: caller is not the owner");
        migration.release();
    }

    function testRevert_ReleaseTooEarly(uint256 timestamp) external {
        vm.assume(timestamp < migration.releaseTimestamp());
        vm.startPrank(governance);
        vm.expectRevert("PolygonMigration: migration is not over");
        migration.release();
    }

    function test_Release(uint256 timestamp) external {
        vm.assume(timestamp >= migration.releaseTimestamp());
        vm.warp(timestamp);
        uint256 balance = polygon.balanceOf(address(migration));
        vm.startPrank(governance);
        migration.release();

        assertEq(polygon.balanceOf(address(migration)), 0);
        assertEq(polygon.balanceOf(governance), balance);
    }
}
