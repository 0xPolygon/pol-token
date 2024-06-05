// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {PolygonEcosystemToken} from "src/PolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "src/DefaultEmissionManager.sol";
import {PolygonMigration} from "src/PolygonMigration.sol";
import {ERC20PresetMinterPauser} from "openzeppelin-contracts/contracts/token/ERC20/presets/ERC20PresetMinterPauser.sol";
import {
    ProxyAdmin,
    TransparentUpgradeableProxy,
    ITransparentUpgradeableProxy
} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {Test} from "forge-std/Test.sol";

// this test forks mainnet and tests the upgradeability of DefaultEmissionManagerProxy

contract DefaultEmissionManagerTest is Test {
    uint256 mainnetFork;

    address POLYGON_PROTOCOL_COUNCIL = 0x37D085ca4a24f6b29214204E8A8666f12cf19516;
    address EM_PROXY = 0xbC9f74b3b14f460a6c47dCdDFd17411cBc7b6c53;
    address COMMUNITY_TREASURY_BOARD = 0x2ff25495d77f380d5F65B95F103181aE8b1cf898;
    address EM_PROXY_ADMIN = 0xEBea33f2c92D03556b417F4F572B2FbbE62C39c3;
    PolygonEcosystemToken pol = PolygonEcosystemToken(0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6);

    uint256 NEW_INTEREST_PER_YEAR_LOG2 = 0.03562390973072122e18; // log2(1.025)

    string[] internal inputs = new string[](5);

    function setUp() public {
        string memory MAINNET_RPC_URL = vm.envString("MAINNET_RPC_URL");
        mainnetFork = vm.createFork(MAINNET_RPC_URL);
    }

    function testUpgrade() external {
        vm.selectFork(mainnetFork);

        address newTreasury = makeAddr("newTreasury");

        DefaultEmissionManager emProxy = DefaultEmissionManager(EM_PROXY);

        assertEq(emProxy.treasury(), COMMUNITY_TREASURY_BOARD);

        address migration = address(emProxy.migration());
        address stakeManager = emProxy.stakeManager();

        DefaultEmissionManager newEmImpl = new DefaultEmissionManager(migration, stakeManager, newTreasury);

        ProxyAdmin admin = ProxyAdmin(EM_PROXY_ADMIN);

        vm.prank(POLYGON_PROTOCOL_COUNCIL);

        admin.upgradeAndCall(
            ITransparentUpgradeableProxy(address(emProxy)),
            address(newEmImpl),
            abi.encodeWithSelector(DefaultEmissionManager.reinitialize.selector)
        );

        // initialize can still not be called
        vm.expectRevert("Initializable: contract is already initialized");
        emProxy.initialize(makeAddr("token"), msg.sender);

        assertEq(pol.totalSupply(), emProxy.START_SUPPLY_1_2_0());
        assertEq(block.timestamp, emProxy.startTimestamp());

        // emission is now 2.5%
        inputs[0] = "node";
        inputs[1] = "test/util/calc.js";
        inputs[2] = vm.toString(uint256(365 days));
        inputs[3] = vm.toString(pol.totalSupply());
        // vm.ffi executes the js script which contains the new emission rate
        uint256 newSupply = abi.decode(vm.ffi(inputs), (uint256));
        assertApproxEqAbs(newSupply, emProxy.inflatedSupplyAfter(365 days), 1e20);

        // treasury has been updated
        assertEq(emProxy.treasury(), newTreasury);
        // emission has been updated
        assertEq(emProxy.INTEREST_PER_YEAR_LOG2(), NEW_INTEREST_PER_YEAR_LOG2);
    }
}
