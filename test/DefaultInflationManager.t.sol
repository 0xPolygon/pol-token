// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

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
}
