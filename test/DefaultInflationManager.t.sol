// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Polygon} from "src/Polygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";

contract DefaultInflationManagerTest is Test {
    error MintPerSecondTooHigh();

    ERC20PresetMinterPauser public matic;
    Polygon public polygon;
    PolygonMigration public migration;
    address public treasury;
    address public stakeManager;
    address public governance;
    DefaultInflationManager public inflationManager;
    DefaultInflationManager public inflationManagerImplementation;

    function setUp() external {
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        governance = makeAddr("governance");
        inflationManagerImplementation = new DefaultInflationManager();
        inflationManager = DefaultInflationManager(
            address(
                new TransparentUpgradeableProxy(
                    address(inflationManagerImplementation),
                    msg.sender,
                    ""
                )
            )
        );
        matic = new ERC20PresetMinterPauser("Matic Token", "MATIC");
        migration = new PolygonMigration(address(matic), governance);
        polygon = new Polygon(address(migration), address(inflationManager));
        vm.prank(governance);
        migration.setPolygonToken(address(polygon));
        inflationManager.initialize(
            address(polygon),
            address(migration),
            stakeManager,
            treasury,
            governance
        );
        // POL being inflationary, while MATIC having a constant supply,
        // the requirement of unmigrating POL to MATIC for StakeManager on each mint
        // is satisfied by a one-time transfer of MATIC to the migration contract
        // from POS bridge
        // note: this requirement will be changed in the future after the hub's launch
        matic.mint(address(migration), 1_000_000_000 * 10 ** 18);
    }

    function testRevert_Initialize() external {
        vm.expectRevert("Initializable: contract is already initialized");
        inflationManager.initialize(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    function test_Deployment() external {
        assertEq(address(inflationManager.token()), address(polygon));
        assertEq(inflationManager.stakeManager(), stakeManager);
        assertEq(inflationManager.treasury(), treasury);
        assertEq(
            inflationManager.stakeManagerMintPerSecond(),
            3170979198376458650
        );
        assertEq(inflationManager.treasuryMintPerSecond(), 3170979198376458650);
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(inflationManager.owner(), governance);
    }

    function test_ImplementationCannotBeInitialized() external {
        vm.expectRevert("Initializable: contract is already initialized");
        DefaultInflationManager(address(inflationManagerImplementation))
            .initialize(
                address(0),
                address(0),
                address(0),
                address(0),
                address(0)
            );
        vm.expectRevert("Initializable: contract is already initialized");
        DefaultInflationManager(address(inflationManager)).initialize(
            address(0),
            address(0),
            address(0),
            address(0),
            address(0)
        );
    }

    function test_Mint() external {
        inflationManager.mint();

        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(matic.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function test_MintDelay(uint128 delay) external {
        vm.assume(delay <= 10 * 365 days);
        skip(delay);
        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        assertEq(
            matic.balanceOf(stakeManager),
            (block.timestamp - lastMint) * 3170979198376458650
        );
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(
            polygon.balanceOf(treasury),
            (block.timestamp - lastMint) * 3170979198376458650
        );
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function test_MintDelayTwice(uint128 delay) external {
        vm.assume(delay < 5 * 365 days);
        skip(delay);
        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        uint256 balance = (block.timestamp - lastMint) * 3170979198376458650;
        assertEq(matic.balanceOf(stakeManager), balance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), balance);
        assertEq(inflationManager.lastMint(), block.timestamp);

        lastMint = inflationManager.lastMint();

        skip(delay);
        inflationManager.mint();

        balance += (block.timestamp - lastMint) * 3170979198376458650;

        assertEq(matic.balanceOf(stakeManager), balance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), balance);
        assertEq(inflationManager.lastMint(), block.timestamp);
    }

    function testRevert_UpdateInflationRates(
        uint256 stakeManagerMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            stakeManagerMintPerSecond >= 3170979198376458650 ||
                treasuryMintPerSecond >= 3170979198376458650
        );
        vm.startPrank(governance);
        vm.expectRevert(MintPerSecondTooHigh.selector);
        inflationManager.updateInflationRates(
            stakeManagerMintPerSecond,
            treasuryMintPerSecond
        );
    }

    function test_UpdateInflationRates(
        uint256 stakeManagerMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            stakeManagerMintPerSecond < 3170979198376458650 &&
                treasuryMintPerSecond < 3170979198376458650
        );
        vm.startPrank(governance);
        inflationManager.updateInflationRates(
            stakeManagerMintPerSecond,
            treasuryMintPerSecond
        );

        assertEq(
            inflationManager.stakeManagerMintPerSecond(),
            stakeManagerMintPerSecond
        );
        assertEq(
            inflationManager.treasuryMintPerSecond(),
            treasuryMintPerSecond
        );
    }

    function test_UpdateInflationRatesAndMint(
        uint128 timestamp,
        uint256 stakeManagerMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            stakeManagerMintPerSecond < 3170979198376458650 &&
                treasuryMintPerSecond < 3170979198376458650 &&
                timestamp > block.timestamp &&
                timestamp < block.timestamp + 10 * 365 days
        );
        vm.startPrank(governance);
        inflationManager.updateInflationRates(
            stakeManagerMintPerSecond,
            treasuryMintPerSecond
        );

        assertEq(
            inflationManager.stakeManagerMintPerSecond(),
            stakeManagerMintPerSecond
        );
        assertEq(
            inflationManager.treasuryMintPerSecond(),
            treasuryMintPerSecond
        );

        vm.warp(timestamp);
        vm.startPrank(governance);

        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(
            matic.balanceOf(stakeManager),
            (block.timestamp - lastMint) * stakeManagerMintPerSecond
        );
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(
            polygon.balanceOf(treasury),
            (block.timestamp - lastMint) * treasuryMintPerSecond
        );
    }

    function test_UpdateInflationRatesAndMintTwice(
        uint128 timestamp,
        uint64 delay,
        uint256 stakeManagerMintPerSecond,
        uint256 treasuryMintPerSecond
    ) external {
        vm.assume(
            stakeManagerMintPerSecond < 3170979198376458650 &&
                treasuryMintPerSecond < 3170979198376458650 &&
                timestamp > block.timestamp &&
                uint256(timestamp) + uint256(delay) < 10 * 365 days
        );
        vm.startPrank(governance);
        inflationManager.updateInflationRates(
            stakeManagerMintPerSecond,
            treasuryMintPerSecond
        );

        assertEq(
            inflationManager.stakeManagerMintPerSecond(),
            stakeManagerMintPerSecond
        );
        assertEq(
            inflationManager.treasuryMintPerSecond(),
            treasuryMintPerSecond
        );

        vm.warp(timestamp);
        vm.startPrank(governance);

        uint256 lastMint = inflationManager.lastMint();
        inflationManager.mint();

        uint256 stakeManagerBalance = (block.timestamp - lastMint) *
            stakeManagerMintPerSecond;
        uint256 treasuryBalance = (block.timestamp - lastMint) *
            treasuryMintPerSecond;
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(matic.balanceOf(stakeManager), stakeManagerBalance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), treasuryBalance);

        skip(delay);
        lastMint = inflationManager.lastMint();
        inflationManager.mint();

        stakeManagerBalance += ((block.timestamp - lastMint) *
            stakeManagerMintPerSecond);
        treasuryBalance += ((block.timestamp - lastMint) *
            treasuryMintPerSecond);
        assertEq(inflationManager.lastMint(), block.timestamp);
        assertEq(matic.balanceOf(stakeManager), stakeManagerBalance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), treasuryBalance);
    }
}
