// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IInflationRateProvider {
    function getAllMintPerSecond() external view returns (uint256 hubMintPerSecond, uint256 treasuryMintPerSecond);

    function getHubMintPerSecond() external view returns (uint256 hubMintPerSecond);

    function getTreasuryMintPerSecond() external view returns (uint256 treasuryMintPerSecond);
}
