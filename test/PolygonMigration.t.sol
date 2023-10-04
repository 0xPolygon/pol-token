// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {PolygonEcosystemToken} from "src/PolygonEcosystemToken.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {IPolygonMigration} from "src/interfaces/IPolygonMigration.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {TransparentUpgradeableProxy, ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {SigUtils} from "test/SigUtils.t.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonMigrationTest is Test {
    ERC20PresetMinterPauser public matic;
    PolygonEcosystemToken public polygon;
    PolygonMigration public migration;
    SigUtils public sigUtils;
    ProxyAdmin public admin;
    address public treasury;
    address public governance;
    address public stakeManager;
    address public emissionManager;

    function setUp() external {
        treasury = makeAddr("treasury");
        governance = makeAddr("governance");
        stakeManager = makeAddr("stakeManager");
        emissionManager = makeAddr("emissionManager");
        matic = new ERC20PresetMinterPauser("Matic Token", "MATIC");
        admin = new ProxyAdmin();
        migration = PolygonMigration(
            address(
                new TransparentUpgradeableProxy(
                    address(new PolygonMigration(address(matic))),
                    address(admin),
                    abi.encodeWithSelector(PolygonMigration.initialize.selector)
                )
            )
        );
        polygon = new PolygonEcosystemToken(
            address(migration),
            address(emissionManager),
            governance,
            makeAddr("permit2revoker")
        );
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
            address(new TransparentUpgradeableProxy(address(new PolygonMigration(address(matic))), msg.sender, ""))
        );
        temp.initialize();
        vm.expectRevert("Initializable: contract is already initialized");
        temp.initialize();

        vm.expectRevert(IPolygonMigration.InvalidAddress.selector);
        new PolygonMigration(address(0));
    }

    function test_Migrate(address user, uint256 amount) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                user != address(0) &&
                user != address(migration) &&
                user != governance &&
                user != address(admin)
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

    function test_Unmigrate(address user, uint256 amount, uint256 amount2) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                amount2 <= amount &&
                user != address(0) &&
                user != address(migration) &&
                user != governance &&
                user != address(admin)
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
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                user != address(0) &&
                user != address(migration) &&
                user != governance &&
                user != address(admin)
        );
        bool unmigrationLock = true;
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

    function test_UnmigrateTo(address user, address migrateTo, uint256 amount, uint256 amount2) external {
        vm.assume(
            amount <= 10000000000 * 10 ** 18 &&
                amount2 <= amount &&
                user != address(0) &&
                user != address(migration) &&
                user != governance &&
                user != migrateTo &&
                user != address(admin) &&
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
        migration.unmigrateTo(migrateTo, amount2);

        assertEq(polygon.balanceOf(user), amount - amount2);
        assertEq(matic.balanceOf(address(migration)), amount - amount2);
        assertEq(matic.balanceOf(user), 0);
        assertEq(matic.balanceOf(migrateTo), amount2);
    }

    function test_UnmigrateWithPermit(uint256 privKey, uint256 amount, uint256 amount2) external {
        address user;
        vm.assume(
            privKey != 0 &&
                privKey < 115792089237316195423570985008687907852837564279074904382605163141518161494337 &&
                (user = vm.addr(privKey)) != address(migration) &&
                user != address(admin) &&
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

    function testRevert_Burn(address caller, uint256 amount) external {
        vm.assume(caller != governance && caller != address(admin));
        vm.prank(caller);
        vm.expectRevert("Ownable: caller is not the owner");
        migration.burn(amount);
    }

    function test_Burn(uint256 amount) external {
        amount = bound(amount, 1, 1e28 /* 10B */);
        assertEq(polygon.balanceOf(address(migration)), 1e28);
        vm.prank(governance);
        migration.burn(amount);
        assertEq(polygon.balanceOf(address(migration)), 1e28 - amount);
        assertEq(polygon.balanceOf(0x000000000000000000000000000000000000dEaD), amount);
    }
}
