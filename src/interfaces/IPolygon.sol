// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";

interface IPolygon is IERC20Permit {
    function mint(address to, uint256 amount) external;
}
