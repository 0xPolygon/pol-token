// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IInflationRateProvider {
    function getHubMintPerSecond() external returns (uint256 hubMintPerSecond);

    function getTreasuryMintPerSecond() external returns (uint256 treasuryMintPerSecond);
}
