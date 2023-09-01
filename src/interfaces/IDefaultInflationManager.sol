// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDefaultInflationManager {
    error InvalidAddress();

    function startTimestamp() external view returns (uint256 timestamp);

    function mint() external;
}
