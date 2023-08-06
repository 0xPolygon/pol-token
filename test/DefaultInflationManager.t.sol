// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IPolygon} from "src/interfaces/IPolygon.sol";
import {Polygon} from "src/Polygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {TransparentUpgradeableProxy} from
    "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

contract DefaultInflationManagerTest is Test {
    Polygon public polygon;
    address public migration;
    address public treasury;
    address public hub;
    address public governance;
    DefaultInflationManager public inflationManager;

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        hub = makeAddr("hub");
        governance = makeAddr("governance");
        inflationManager = DefaultInflationManager(
            address(new TransparentUpgradeableProxy(address(new DefaultInflationManager()), msg.sender, ""))
        );
        polygon = new Polygon(migration, address(inflationManager));
        inflationManager.initialize(IPolygon(address(polygon)), hub, treasury, governance);
    }

    function testRevert_Initialize() external {
        vm.expectRevert("Initializable: contract is already initialized");
        inflationManager.initialize(IPolygon(address(0)), address(0), address(0), address(0));
    }

    function test_Deployment() external {
        assertEq(address(inflationManager.token()), address(polygon));
        assertEq(inflationManager.hub(), hub);
        assertEq(inflationManager.treasury(), treasury);
        assertEq(inflationManager.hubMintPerSecond(), 3170979198376458650);
        assertEq(inflationManager.treasuryMintPerSecond(), 3170979198376458650);
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(inflationManager.owner(), governance);
    }

    function test_Mint() external {
        inflationManager.mint();

        assertEq(polygon.balanceOf(hub), 0);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function test_MintDelay(uint128 delay) external {
        skip(delay);
        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        assertEq(polygon.balanceOf(hub), (block.timestamp - lastMint) * 3170979198376458650);
        assertEq(polygon.balanceOf(treasury), (block.timestamp - lastMint) * 3170979198376458650);
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function test_MintDelayTwice(uint128 delay) external {
        skip(delay);
        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        uint256 balance = (block.timestamp - lastMint) * 3170979198376458650;
        assertEq(polygon.balanceOf(hub), balance);
        assertEq(polygon.balanceOf(treasury), balance);
        assertEq(inflationManager.lastMint(), block.timestamp);

        lastMint = inflationManager.lastMint();

        skip(delay);
        inflationManager.mint();

        balance += (block.timestamp - lastMint) * 3170979198376458650;

        assertEq(polygon.balanceOf(hub), balance);
        assertEq(polygon.balanceOf(treasury), balance);
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function testRevert_UpdateInflationRates(uint256 hubMintPerSecond, uint256 treasuryMintPerSecond) external {
        vm.assume(hubMintPerSecond >= 3170979198376458650 || treasuryMintPerSecond >= 3170979198376458650);
        vm.startPrank(governance);
        vm.expectRevert("DefaultInflationManager: mint per second too high");
        inflationManager.updateInflationRates(hubMintPerSecond, treasuryMintPerSecond);
    }

    function test_UpdateInflationRates(uint256 hubMintPerSecond, uint256 treasuryMintPerSecond) external {
        vm.assume(hubMintPerSecond < 3170979198376458650 && treasuryMintPerSecond < 3170979198376458650);
        vm.startPrank(governance);
        inflationManager.updateInflationRates(hubMintPerSecond, treasuryMintPerSecond);

        assertEq(inflationManager.hubMintPerSecond(), hubMintPerSecond);
        assertEq(inflationManager.treasuryMintPerSecond(), treasuryMintPerSecond);
    }

    function test_UpdateInflationRatesAndMint(
        uint128 timestamp,
        uint256 hubMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            hubMintPerSecond < 3170979198376458650 && treasuryMintPerSecond < 3170979198376458650
                && timestamp > block.timestamp
        );
        vm.startPrank(governance);
        inflationManager.updateInflationRates(hubMintPerSecond, treasuryMintPerSecond);

        assertEq(inflationManager.hubMintPerSecond(), hubMintPerSecond);
        assertEq(inflationManager.treasuryMintPerSecond(), treasuryMintPerSecond);

        vm.warp(timestamp);
        vm.startPrank(governance);

        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(polygon.balanceOf(hub), (block.timestamp - lastMint) * hubMintPerSecond);
        assertEq(polygon.balanceOf(treasury), (block.timestamp - lastMint) * treasuryMintPerSecond);
    }

    function test_UpdateInflationRatesAndMintTwice(
        uint128 timestamp,
        uint64 delay,
        uint256 hubMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            hubMintPerSecond < 3170979198376458650 && treasuryMintPerSecond < 3170979198376458650
                && timestamp > block.timestamp
        );
        vm.startPrank(governance);
        inflationManager.updateInflationRates(hubMintPerSecond, treasuryMintPerSecond);

        assertEq(inflationManager.hubMintPerSecond(), hubMintPerSecond);
        assertEq(inflationManager.treasuryMintPerSecond(), treasuryMintPerSecond);

        vm.warp(timestamp);
        vm.startPrank(governance);

        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        uint256 hubBalance = (block.timestamp - lastMint) * hubMintPerSecond;
        uint256 treasuryBalance = (block.timestamp - lastMint) * treasuryMintPerSecond;
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(polygon.balanceOf(hub), hubBalance);
        assertEq(polygon.balanceOf(treasury), treasuryBalance);

        skip(delay);
        lastMint = inflationManager.lastMint();
        inflationManager.mint();

        hubBalance += ((block.timestamp - lastMint) * hubMintPerSecond);
        treasuryBalance += ((block.timestamp - lastMint) * treasuryMintPerSecond);
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(polygon.balanceOf(hub), hubBalance);
        assertEq(polygon.balanceOf(treasury), treasuryBalance);
    }
}
