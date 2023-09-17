// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IAccessControlEnumerable} from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

interface IPolygonEcosystemToken is IERC20, IERC20Permit, IAccessControlEnumerable {
    event MintCapUpdated(uint256 oldCap, uint256 newCap);
    event Permit2Revoked();

    error InvalidAddress();
    error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);

    function mint(address to, uint256 amount) external;

    function updateMintCap(uint256 newCap) external;
}
