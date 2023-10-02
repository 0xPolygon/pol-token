// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IAccessControlEnumerable} from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

interface IPolygonEcosystemToken is IERC20, IERC20Permit, IAccessControlEnumerable {
    event MintCapUpdated(uint256 oldCap, uint256 newCap);
    event Permit2AllowanceUpdated(bool enabled);

    error InvalidAddress();
    error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);

    function mintPerSecondCap() external view returns (uint256 currentMintPerSecondCap);

    function lastMint() external view returns (uint256 lastMintTimestamp);

    function permit2Enabled() external view returns (bool isPermit2Enabled);

    function mint(address to, uint256 amount) external;

    function updateMintCap(uint256 newCap) external;

    function updatePermit2Allowance(bool enabled) external;
}
