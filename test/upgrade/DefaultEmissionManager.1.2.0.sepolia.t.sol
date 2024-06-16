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

contract DefaultEmissionManagerTestSepolia is Test {
    uint256 fork;

    address POLYGON_PROTOCOL_COUNCIL = 0xeE76bECaF80fFe451c8B8AFEec0c21518Def02f9;
    address EM_PROXY = 0x20393fF3B3C38b72a16eB7d7A474cd38ABD8Ff27;
    address COMMUNITY_TREASURY = 0xeE76bECaF80fFe451c8B8AFEec0c21518Def02f9;
    address EM_PROXY_ADMIN = 0x28cDCE6FfE44D03da1F7b15b474a0e72243873F2;
    PolygonEcosystemToken pol = PolygonEcosystemToken(0x44499312f493F62f2DFd3C6435Ca3603EbFCeeBa);

    uint256 NEW_INTEREST_PER_YEAR_LOG2 = 0.03562390973072122e18; // log2(1.025)

    string[] internal inputs = new string[](5);

    function setUp() public {
        fork = vm.createFork(vm.rpcUrl("testnet"));
    }

    function testUpgrade() external {
        vm.selectFork(fork);

        address newTreasury = makeAddr("newTreasury");

        DefaultEmissionManager emProxy = DefaultEmissionManager(EM_PROXY);

        assertEq(emProxy.treasury(), COMMUNITY_TREASURY);

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
