// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IDefaultEmissionManager {
    error InvalidAddress();

    event TokenMint(uint256 amount, address caller);

    function startTimestamp() external view returns (uint256 timestamp);

    function mint() external;
}
