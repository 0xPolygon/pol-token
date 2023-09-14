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
    DefaultEmissionManager public emissionManager;
    uint256 public constant mintPerSecondCap = 0.0000000420e18; // 0.0000042% of POL Supply per second, in 18 decimals

    function setUp() external {
        migration = makeAddr("migration");
        treasury = makeAddr("treasury");
        stakeManager = makeAddr("stakeManager");
        matic = makeAddr("matic");
        ProxyAdmin admin = new ProxyAdmin();
        emissionManager = DefaultEmissionManager(
            address(new TransparentUpgradeableProxy(address(new DefaultEmissionManager()), address(admin), ""))
        );
        polygon = new PolygonEcosystemToken(migration, address(emissionManager));
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
        assertEq(polygon.emissionManager(), address(emissionManager));
    }

    function test_InvalidDeployment() external {
        PolygonEcosystemToken token;
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(makeAddr("migration"), address(0));
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(address(0), makeAddr("emissionManager"));
        vm.expectRevert(IPolygonEcosystemToken.InvalidAddress.selector);
        token = new PolygonEcosystemToken(address(0), address(0));
    }

    function testRevert_Mint(address user, address to, uint256 amount) external {
        vm.assume(user != address(emissionManager));
        vm.startPrank(user);
        vm.expectRevert(IPolygonEcosystemToken.OnlyEmissionManager.selector);
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

        uint256 maxMint = (mintPerSecondCap * delay * polygon.totalSupply()) / 1e18;
        if (amount > maxMint)
            vm.expectRevert(abi.encodeWithSelector(IPolygonEcosystemToken.MaxMintExceeded.selector, maxMint, amount));
        vm.prank(address(emissionManager));
        polygon.mint(to, amount);

        if (amount <= maxMint) assertEq(polygon.balanceOf(to), amount);
    }
}
