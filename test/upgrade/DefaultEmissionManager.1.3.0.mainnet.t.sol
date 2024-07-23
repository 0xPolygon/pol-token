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

contract DefaultEmissionManagerTestMainnet is Test {
    uint256 mainnetFork;

    address POLYGON_PROTOCOL_COUNCIL = 0x37D085ca4a24f6b29214204E8A8666f12cf19516;
    address EM_PROXY = 0xbC9f74b3b14f460a6c47dCdDFd17411cBc7b6c53;
    address COMMUNITY_TREASURY = 0x86380e136A3AaD5677A210Ad02713694c4E6a5b9;
    address EM_PROXY_ADMIN = 0xEBea33f2c92D03556b417F4F572B2FbbE62C39c3;
    PolygonEcosystemToken pol = PolygonEcosystemToken(0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6);

    uint256 NEW_INTEREST_PER_YEAR_LOG2 = 0.03562390973072122e18; // log2(1.025)

    string[] internal inputs = new string[](5);

    function setUp() public {
        mainnetFork = vm.createFork(vm.rpcUrl("mainnet"));
    }

    function testUpgrade() external {
        vm.selectFork(mainnetFork);

        DefaultEmissionManager emProxy = DefaultEmissionManager(EM_PROXY);

        assertEq(emProxy.treasury(), COMMUNITY_TREASURY);

        address migration = address(emProxy.migration());
        address stakeManager = emProxy.stakeManager();
        address treasury = emProxy.treasury();

        DefaultEmissionManager newEmImpl = new DefaultEmissionManager(migration, stakeManager, treasury);

        ProxyAdmin admin = ProxyAdmin(EM_PROXY_ADMIN);

        vm.prank(POLYGON_PROTOCOL_COUNCIL);

        admin.upgrade(
            ITransparentUpgradeableProxy(address(emProxy)),
            address(newEmImpl)
        );
    }
}
