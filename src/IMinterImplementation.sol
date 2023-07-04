// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IMinterImplementation {
    function getHubMintPerSecond() external returns (uint256);

    function getTreasuryMintPerSecond() external returns (uint256);
}
