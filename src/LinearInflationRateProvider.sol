// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IInflationRateProvider} from "./interfaces/IInflationRateProvider.sol";

contract LinearInflationRateProvider is IInflationRateProvider {
    uint256 private immutable _mintPerSecond = 3170979198376458650;
    uint256 public immutable duration;

    constructor(uint256 duration_) {
        duration = duration_;
    }

    function getHubMintPerSecond() external view returns (uint256 hubMintPerSecond) {
        hubMintPerSecond = _mintPerSecond * (duration - block.timestamp) / duration;
    }

    function getTreasuryMintPerSecond() external view returns (uint256 treasuryMintPerSecond) {
        treasuryMintPerSecond = _mintPerSecond * (duration - block.timestamp) / duration;
    }
}
