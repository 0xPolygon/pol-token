// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {PolygonEcosystemToken} from "src/PolygonEcosystemToken.sol";
import {IPolygonEcosystemToken} from "src/interfaces/IPolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "src/DefaultEmissionManager.sol";
import {TransparentUpgradeableProxy, ProxyAdmin} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {Test} from "forge-std/Test.sol";

contract PolygonTest is Test {
    PolygonEcosystemToken public polygon;
    address public matic;
    address public migration;
    address public treasury;
    address public stakeManager;
    address public ecosystemCouncil; // timelocked multisig - responsible for changing max mint cap
    DefaultEmissionManager public emissionManager;
    uint256 public mintPerSecondCap = 10e18; // 10 POL tokens per second
    uint256 internal constant MAX_MINT_PER_SECOND = 10e18;

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        matic = makeAddr("matic");
        ecosystemCouncil = makeAddr("ecosystemCouncil");
        ProxyAdmin admin = new ProxyAdmin();
        emissionManager = DefaultEmissionManager(
            address(new TransparentUpgradeableProxy(address(new DefaultEmissionManager()), address(admin), ""))
        );
        polygon = new PolygonEcosystemToken(migration, address(emissionManager), ecosystemCouncil);
        emissionManager.initialize(address(polygon), migration, stakeManager, treasury, msg.sender);
    }

    function test_Deployment() external {
        assertEq(polygon.name(), "Polygon Ecosystem Token");
        assertEq(polygon.symbol(), "POL");
        assertEq(polygon.decimals(), 18);
        assertEq(polygon.totalSupply(), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(migration), 10000000000 * 10 ** 18);
        assertEq(polygon.balanceOf(treasury), 0);
        assertEq(polygon.balanceOf(stakeManager), 0);

        // only ecosystemCouncil has DEFAULT_ADMIN_ROLE
        assertTrue(polygon.hasRole(polygon.DEFAULT_ADMIN_ROLE(), ecosystemCouncil));
        assertEq(polygon.getRoleMemberCount(polygon.DEFAULT_ADMIN_ROLE()), 1, "DEFAULT_ADMIN_ROLE incorrect assignees");
        // only ecosystemCouncil has CAP_MANAGER_ROLE
        assertTrue(polygon.hasRole(polygon.CAP_MANAGER_ROLE(), ecosystemCouncil));
        assertEq(polygon.getRoleMemberCount(polygon.CAP_MANAGER_ROLE()), 1, "CAP_MANAGER_ROLE incorrect assignees");
        // only emissionManager has EMISSION_ROLE
        assertTrue(polygon.hasRole(polygon.EMISSION_ROLE(), address(emissionManager)));
        assertEq(polygon.getRoleMemberCount(polygon.EMISSION_ROLE()), 1, "EMISSION_ROLE incorrect assignees");
    }

    function test_InvalidDeployment() external {
        PolygonEcosystemToken token;
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(makeAddr("migration"), address(0), address(0));
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(address(0), makeAddr("emissionManager"), address(0));
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(address(0), address(0), makeAddr("ecosystemCouncil"));
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(address(0), address(0), address(0));
    }

    function testUpdateMintCap(uint256 newCap) external {
        vm.prank(ecosystemCouncil);
        if (newCap > MAX_MINT_PER_SECOND) vm.expectRevert(IPolygonEcosystemToken.InvalidMintCapUpdate.selector);
        polygon.updateMintCap(newCap);
        if (newCap <= MAX_MINT_PER_SECOND) assertEq(polygon.mintPerSecondCap(), newCap);
    }

    function testRevert_UpdateMintCap(uint256 newCap, address caller) external {
        vm.assume(caller != ecosystemCouncil);
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
        skip(1e8); // delay needed for a max mint of 10B
        vm.assume(to != address(0) && amount <= 10000000000 * 10 ** 18 && to != migration);
        vm.prank(address(emissionManager));
        polygon.mint(to, amount);

        assertEq(polygon.balanceOf(to), amount);
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
