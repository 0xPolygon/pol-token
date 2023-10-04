// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {Script, stdJson, console2 as console} from "forge-std/Script.sol";

import {ProxyAdmin, TransparentUpgradeableProxy} from "openzeppelin-contracts/contracts/proxy/transparent/ProxyAdmin.sol";
import {PolygonEcosystemToken} from "../src/PolygonEcosystemToken.sol";
import {DefaultEmissionManager} from "../src/DefaultEmissionManager.sol";
import {PolygonMigration} from "../src/PolygonMigration.sol";

contract Deploy is Script {
    using stdJson for string;

    string internal constant TEST_MNEMONIC = "test test test test test test test test test test test junk";
    uint256 public deployerPrivateKey;

    constructor() {
        deployerPrivateKey = vm.envOr({name: "PRIVATE_KEY", defaultValue: uint256(0)});
        if (deployerPrivateKey == 0) {
            (, deployerPrivateKey) = deriveRememberKey({mnemonic: TEST_MNEMONIC, index: 0});
        }
    }

    function _getLatestCommitHash() internal returns (string memory ret) {
        string[] memory input = new string[](3);
        input[0] = "git";
        input[1] = "rev-parse";
        input[2] = "HEAD";
        ret = vm.toString(vm.ffi(input));
    }

    function _extractBroadcastAndUpdate() internal {
        string[] memory input = new string[](3);
        input[0] = "node";
        input[1] = "script/utils/extract.js";
        input[2] = vm.toString(block.chainid);
        bytes memory out = vm.ffi(input);
        if (out.length == 0) console.log("extractBroadcastAndUpdate successful");
        else console.log("extractBroadcastAndUpdate:", string(out));
    }

    modifier postHook() {
        _;
        _extractBroadcastAndUpdate();
    }

    function run() public postHook {
        string memory config = vm.readFile("script/config.json");
        string memory chainIdSlug = string(abi.encodePacked('["', vm.toString(block.chainid), '"]'));
        address matic = config.readAddress(string.concat(chainIdSlug, ".matic"));
        address governance = config.readAddress(string.concat(chainIdSlug, ".governance"));
        address treasury = config.readAddress(string.concat(chainIdSlug, ".treasury"));
        address stakeManager = config.readAddress(string.concat(chainIdSlug, ".stakeManager"));
        address permit2revoker = config.readAddress(string.concat(chainIdSlug, ".permit2revoker"));

        vm.startBroadcast(deployerPrivateKey);

        ProxyAdmin admin = new ProxyAdmin();
        admin.transferOwnership(governance);

        address migrationImplementation = address(new PolygonMigration(matic));

        address migrationProxy = address(
            new TransparentUpgradeableProxy(
                migrationImplementation,
                address(admin),
                abi.encodeWithSelector(PolygonMigration.initialize.selector)
            )
        );

        address emissionManagerImplementation = address(
            new DefaultEmissionManager(migrationProxy, stakeManager, treasury)
        );
        address emissionManagerProxy = address(
            new TransparentUpgradeableProxy(address(emissionManagerImplementation), address(admin), "")
        );

        PolygonEcosystemToken polygonToken = new PolygonEcosystemToken(
            migrationProxy,
            emissionManagerProxy,
            governance,
            permit2revoker
        );

        DefaultEmissionManager(emissionManagerProxy).initialize(address(polygonToken), governance);

        PolygonMigration(migrationProxy).setPolygonToken(address(polygonToken));

        PolygonMigration(migrationProxy).transferOwnership(governance); // governance needs to accept the ownership transfer

        vm.stopBroadcast();
    }
}
