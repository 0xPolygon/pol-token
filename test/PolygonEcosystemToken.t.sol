// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {PolygonEcosystemToken} from "src/PolygonEcosystemToken.sol";
import {IPolygonEcosystemToken} from "src/interfaces/IPolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "src/DefaultEmissionManager.sol";
import {TransparentUpgradeableProxy, ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonTest is Test {
    event Permit2AllowanceUpdated(bool enabled);

    PolygonEcosystemToken public polygon;
    address public matic;
    address public migration;
    address public treasury;
    address public stakeManager;
    address public governance;
    address public permit2revoker;
    DefaultEmissionManager public emissionManager;
    uint256 public mintPerSecondCap = 10e18; // 10 POL tokens per second

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        matic = makeAddr("matic");
        governance = makeAddr("governance");
        permit2revoker = makeAddr("permit2revoker");
        ProxyAdmin admin = new ProxyAdmin();
        emissionManager = DefaultEmissionManager(
            address(new TransparentUpgradeableProxy(address(new DefaultEmissionManager()), address(admin), ""))
        );
        polygon = new PolygonEcosystemToken(migration, address(emissionManager), governance, permit2revoker);
        emissionManager.initialize(address(polygon), migration, stakeManager, treasury, msg.sender);
    }

    function test_Deployment(address owner) external {
        assertEq(polygon.name(), "Polygon Ecosystem Token");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(polygon.balanceOf(stakeManager), 0);
        assertTrue(polygon.permit2Enabled());
        assertEq(polygon.allowance(owner, polygon.PERMIT2()), type(uint256).max);

        // only governance has DEFAULT_ADMIN_ROLE
        assertTrue(polygon.hasRole(polygon.DEFAULT_ADMIN_ROLE(), governance));
        assertEq(polygon.getRoleMemberCount(polygon.DEFAULT_ADMIN_ROLE()), 1, "DEFAULT_ADMIN_ROLE incorrect assignees");
        // only governance has CAP_MANAGER_ROLE
        assertTrue(polygon.hasRole(polygon.CAP_MANAGER_ROLE(), governance));
        assertEq(polygon.getRoleMemberCount(polygon.CAP_MANAGER_ROLE()), 1, "CAP_MANAGER_ROLE incorrect assignees");
        // only emissionManager has EMISSION_ROLE
        assertTrue(polygon.hasRole(polygon.EMISSION_ROLE(), address(emissionManager)));
        assertEq(polygon.getRoleMemberCount(polygon.EMISSION_ROLE()), 1, "EMISSION_ROLE incorrect assignees");
        // only governance has PERMIT2_REVOKER_ROLE
        assertTrue(polygon.hasRole(polygon.PERMIT2_REVOKER_ROLE(), permit2revoker));
        assertEq(
            polygon.getRoleMemberCount(polygon.PERMIT2_REVOKER_ROLE()),
            1,
            "PERMIT2_REVOKER_ROLE incorrect assignees"
        );
    }

    function test_InvalidDeployment() external {
        PolygonEcosystemToken token;
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(
            address(0),
            makeAddr("emissionManager"),
            makeAddr("governance"),
            makeAddr("revoker")
        );
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(
            makeAddr("migration"),
            address(0),
            makeAddr("governance"),
            makeAddr("revoker")
        );
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(
            makeAddr("migration"),
            makeAddr("emissionManager"),
            address(0),
            makeAddr("revoker")
        );
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(
            makeAddr("migration"),
            makeAddr("emissionManager"),
            makeAddr("governance"),
            address(0)
        );
    }

    function testRevert_UpdateMintCap(uint256 newCap, address caller) external {
        vm.assume(caller != governance);
        vm.prank(caller);
        vm.expectRevert();
        polygon.updateMintCap(newCap);
    }

    function testRevert_Mint(address user, address to, uint256 amount) external {
        vm.assume(user != address(emissionManager));
        vm.startPrank(user);
        vm.expectRevert();
        polygon.mint(to, amount);
    }

    function test_Mint(address to, uint256 amount) external {
        skip(1e9); // delay needed for a max mint of 10B
        vm.assume(to != address(0) && amount <= 10000000000 * 10 ** 18 && to != migration);
        vm.prank(address(emissionManager));
        polygon.mint(to, amount);

        assertEq(polygon.balanceOf(to), amount);
    }

    function testRevert_Permit2Revoke(address user) external {
        vm.assume(user != permit2revoker);
        vm.startPrank(user);
        vm.expectRevert();
        polygon.updatePermit2Allowance(false);
    }

    function test_RevokePermit2Allowance(address owner) external {
        assertEq(polygon.allowance(owner, polygon.PERMIT2()), type(uint256).max);
        vm.prank(permit2revoker);
        vm.expectEmit(true, true, true, true);
        emit Permit2AllowanceUpdated(false);
        polygon.updatePermit2Allowance(false);
        assertFalse(polygon.permit2Enabled());
        assertEq(polygon.allowance(owner, polygon.PERMIT2()), 0);
    }

    function test_MintMaxExceeded(address to, uint256 amount, uint256 delay) external {
        vm.assume(to != address(0) && amount <= 10000000000 * 10 ** 18 && to != migration && delay < 10 * 365 days);
        skip(++delay); // avoid delay == 0

        uint256 maxMint = delay * mintPerSecondCap;
        if (amount > maxMint)
            vm.expectRevert(abi.encodeWithSelector(IPolygonEcosystemToken.MaxMintExceeded.selector, maxMint, amount));
        vm.prank(address(emissionManager));
        polygon.mint(to, amount);

        if (amount <= maxMint) assertEq(polygon.balanceOf(to), amount);
    }
}
