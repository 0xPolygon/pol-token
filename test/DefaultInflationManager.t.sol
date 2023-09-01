// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Polygon} from "src/Polygon.sol";
import {DefaultInflationManager} from "src/DefaultInflationManager.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {Test} from "forge-std/Test.sol";

contract DefaultInflationManagerTest is Test {
    error InvalidAddress();

    ERC20PresetMinterPauser public matic;
    Polygon public polygon;
    PolygonMigration public migration;
    address public treasury;
    address public stakeManager;
    address public governance;
    DefaultInflationManager public inflationManager;
    DefaultInflationManager public inflationManagerImplementation;

    // precision accuracy due to log2 approximation is up to the first 5 digits
    uint256 private constant _MAX_PRECISION_DELTA = 1e13;

    string[] internal inputs = new string[](4);

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
        migration = PolygonMigration(
            address(
                new TransparentUpgradeableProxy(
                    address(new PolygonMigration()),
                    msg.sender,
                    ""
                )
            )
        );
        migration.initialize(address(matic));
        polygon = new Polygon(address(migration), address(inflationManager));
        migration.setPolygonToken(address(polygon)); // deployer sets token
        migration.transferOwnership(governance);
        vm.prank(governance);
        migration.acceptOwnership();
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
        matic.mint(address(migration), 3_000_000_000e18);

        inputs[0] = "node";
        inputs[1] = "test/util/calc.js";
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
        assertEq(inflationManager.owner(), governance);
        assertEq(
            polygon.allowance(address(inflationManager), address(migration)),
            type(uint256).max
        );
        assertEq(inflationManager.START_SUPPLY(), 10_000_000_000e18);
        assertEq(polygon.totalSupply(), 10_000_000_000e18);
    }

    function test_InvalidDeployment(uint256 seed) external {
        address[5] memory params = [
            makeAddr("polygon"),
            makeAddr("migration"),
            makeAddr("stakeManager"),
            makeAddr("treasury"),
            makeAddr("governance")
        ];
        params[seed % params.length] = address(0); // any one is zero addr

        address proxy = address(
            new TransparentUpgradeableProxy(
                address(new DefaultInflationManager()),
                msg.sender,
                ""
            )
        );
        vm.expectRevert(InvalidAddress.selector);
        DefaultInflationManager(proxy).initialize(
            params[0],
            params[1],
            params[2],
            params[3],
            params[4]
        );
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
        // timeElapsed is zero, so no minting
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(matic.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), 0);
    }

    function test_MintDelay(uint128 delay) external {
        vm.assume(delay <= 10 * 365 days);

        uint256 initialTotalSupply = polygon.totalSupply();

        skip(delay);

        inflationManager.mint();

        inputs[2] = vm.toString(delay);
        inputs[3] = vm.toString(initialTotalSupply);
        uint256 newSupply = abi.decode(vm.ffi(inputs), (uint256));

        assertApproxEqAbs(
            newSupply,
            polygon.totalSupply(),
            _MAX_PRECISION_DELTA
        );
        assertEq(
            matic.balanceOf(stakeManager),
            (polygon.totalSupply() - initialTotalSupply) / 2
        );
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(
            polygon.balanceOf(treasury),
            (polygon.totalSupply() - initialTotalSupply) / 2
        );
    }

    function test_MintDelayTwice(uint128 delay) external {
        vm.assume(delay <= 5 * 365 days && delay > 0);

        uint256 initialTotalSupply = polygon.totalSupply();

        skip(delay);
        inflationManager.mint();

        inputs[2] = vm.toString(delay);
        inputs[3] = vm.toString(initialTotalSupply);
        uint256 newSupply = abi.decode(vm.ffi(inputs), (uint256));

        assertApproxEqAbs(
            newSupply,
            polygon.totalSupply(),
            _MAX_PRECISION_DELTA
        );
        uint256 balance = (polygon.totalSupply() - initialTotalSupply) / 2;
        assertEq(matic.balanceOf(stakeManager), balance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), balance);

        initialTotalSupply = polygon.totalSupply(); // for the new run
        skip(delay);
        inflationManager.mint();

        inputs[2] = vm.toString(delay * 2);
        inputs[3] = vm.toString(initialTotalSupply);
        newSupply = abi.decode(vm.ffi(inputs), (uint256));

        assertApproxEqAbs(
            newSupply,
            polygon.totalSupply(),
            _MAX_PRECISION_DELTA
        );
        balance += (polygon.totalSupply() - initialTotalSupply) / 2;
        assertEq(matic.balanceOf(stakeManager), balance);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertEq(polygon.balanceOf(treasury), balance);
    }

    function test_MintDelayAfterNCycles(uint128 delay, uint8 cycles) external {
        vm.assume(
            delay * uint256(cycles) <= 10 * 365 days && delay > 0 && cycles < 30
        );

        uint256 balance;

        for (uint256 cycle; cycle < cycles; cycle++) {
            uint256 initialTotalSupply = polygon.totalSupply();

            skip(delay);
            inflationManager.mint();

            inputs[2] = vm.toString(delay * (cycle + 1));
            inputs[3] = vm.toString(initialTotalSupply);
            uint256 newSupply = abi.decode(vm.ffi(inputs), (uint256));

            assertApproxEqAbs(
                newSupply,
                polygon.totalSupply(),
                _MAX_PRECISION_DELTA
            );
            balance += (polygon.totalSupply() - initialTotalSupply) / 2;
            assertEq(matic.balanceOf(stakeManager), balance);
            assertEq(polygon.balanceOf(stakeManager), 0);
            assertEq(polygon.balanceOf(treasury), balance);
        }
    }
}
