// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Polygon} from "src/Polygon.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {IPolygonMigration} from "src/interfaces/IPolygonMigration.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";
import {SigUtils} from "test/SigUtils.t.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonMigrationTest is Test {
    ERC20PresetMinterPauser public matic;
    Polygon public polygon;
    PolygonMigration public migration;
    SigUtils public sigUtils;
    address public treasury;
    address public stakeManager;
    address public inflationManager;
    address public governance;

    function setUp() external {
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        inflationManager = makeAddr("inflationManager");
        governance = makeAddr("governance");
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
        sigUtils = new SigUtils(polygon.DOMAIN_SEPARATOR());

        migration.setPolygonToken(address(polygon)); // deployer sets token
        migration.transferOwnership(governance); // deployer transfers ownership
        vm.prank(governance);
        migration.acceptOwnership(); // governance accepts ownership
    }

    function test_Deployment() external {
        assertEq(address(migration.polygon()), address(polygon));
        assertEq(address(migration.matic()), address(matic));
        assertEq(migration.owner(), governance);
    }

    function test_InvalidDeployment() external {
        PolygonMigration temp = PolygonMigration(
            address(
                new TransparentUpgradeableProxy(
                    address(new PolygonMigration()),
                    msg.sender,
                    ""
                )
            )
        );
        vm.expectRevert(IPolygonMigration.InvalidAddress.selector);
        temp.initialize(address(0));
    }

    function test_Migrate(address user, uint256 amount) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                user != address(0) &&
                user != address(migration) &&
                user != governance
        );
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(address(migration)), amount);
        assertEq(polygon.balanceOf(user), amount);
    }

    function test_CannotResetPolygonToken() external {
        address user = makeAddr("user");
        vm.prank(user);
        vm.expectRevert("Ownable: caller is not the owner");
        migration.setPolygonToken(address(polygon));

        vm.startPrank(governance);
        vm.expectRevert(IPolygonMigration.InvalidAddressOrAlreadySet.selector);
        migration.setPolygonToken(address(polygon));

        vm.expectRevert(IPolygonMigration.InvalidAddressOrAlreadySet.selector);
        migration.setPolygonToken(address(0));
        vm.stopPrank();
    }

    function test_Unmigrate(
        address user,
        uint256 amount,
        uint256 amount2
    ) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                amount2 <= amount &&
                user != address(0) &&
                user != address(migration) &&
                user != governance
        );
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(address(migration)), amount);
        assertEq(polygon.balanceOf(user), amount);

        polygon.approve(address(migration), amount2);
        migration.unmigrate(amount2);

        assertEq(polygon.balanceOf(user), amount - amount2);
        assertEq(matic.balanceOf(address(migration)), amount - amount2);
        assertEq(matic.balanceOf(user), amount2);
    }

    function testRevert_Unmigrate(address user, uint256 amount) external {
        bool unmigrationLock = true;
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                user != address(0) &&
                user != address(migration) &&
                user != governance
        );
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);
        vm.stopPrank();

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(address(migration)), amount);
        assertEq(polygon.balanceOf(user), amount);
        vm.prank(governance);
        migration.updateUnmigrationLock(unmigrationLock);

        vm.startPrank(user);
        vm.expectRevert(IPolygonMigration.UnmigrationLocked.selector);
        migration.unmigrate(amount);
        vm.stopPrank();
    }

    function test_UnmigrateTo(
        address user,
        address migrateTo,
        uint256 amount,
        uint256 amount2
    ) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                amount2 <= amount &&
                user != address(0) &&
                user != address(migration) &&
                user != governance &&
                user != migrateTo &&
                migrateTo != address(0) &&
                migrateTo != address(migration)
        );
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(address(migration)), amount);
        assertEq(polygon.balanceOf(user), amount);

        polygon.approve(address(migration), amount2);
        migration.unmigrateTo(amount2, migrateTo);

        assertEq(polygon.balanceOf(user), amount - amount2);
        assertEq(matic.balanceOf(address(migration)), amount - amount2);
        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(migrateTo), amount2);
    }

    function test_UnmigrateWithPermit(
        uint256 privKey,
        uint256 amount,
        uint256 amount2
    ) external {
        address user;
        vm.assume(
            privKey != 0 &&
                privKey <
                115792089237316195423570985008687907852837564279074904382605163141518161494337 &&
                (user = vm.addr(privKey)) != address(migration) &&
                user != governance &&
                amount <= 10000000000 * 10 ** 18 &&
                amount2 <= amount
        );
        matic.mint(user, amount);
        vm.startPrank(user);
        matic.approve(address(migration), amount);
        migration.migrate(amount);

        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(address(migration)), amount);
        assertEq(polygon.balanceOf(user), amount);

        uint256 deadline = 1 minutes;
        SigUtils.Permit memory permit = SigUtils.Permit({
            owner: user,
            spender: address(migration),
            value: amount2,
            nonce: 0,
            deadline: deadline
        });
        bytes32 digest = sigUtils.getTypedDataHash(permit);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKey, digest);
        migration.unmigrateWithPermit(amount2, deadline, v, r, s);

        assertEq(polygon.balanceOf(user), amount - amount2);
        assertEq(matic.balanceOf(address(migration)), amount - amount2);
        assertEq(matic.balanceOf(user), amount2);
    }
}
