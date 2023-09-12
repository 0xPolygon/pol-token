// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPolygonEcosystemToken is IERC20, IERC20Permit {
    error OnlyInflationManager();
    error InvalidAddress();
    error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);

    function mint(address to, uint256 amount) external;
}
