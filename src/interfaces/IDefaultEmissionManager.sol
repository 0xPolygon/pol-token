// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IPolygonEcosystemToken} from "./IPolygonEcosystemToken.sol";

interface IDefaultEmissionManager {
    error InvalidAddress();

    event TokenMint(uint256 amount, address caller);

    function getVersion() external pure returns (string memory version);

    function token() external view returns (IPolygonEcosystemToken polygonEcosystemToken);

    function startTimestamp() external view returns (uint256 timestamp);

    function mint() external;

    function inflatedSupplyAfter(uint256 timeElapsedInSeconds) external pure returns (uint256 inflatedSupply);
}
