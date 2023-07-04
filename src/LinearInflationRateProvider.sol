// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IInflationRateProvider} from "./interfaces/IInflationRateProvider.sol";

contract LinearInflationRateProvider is IInflationRateProvider {
    uint256 private immutable _mintPerSecond = 3170979198376458650;
    uint256 public immutable endTimestamp;
    uint256 public immutable duration;

    constructor(uint256 endTimestamp_, uint256 duration_) {
        endTimestamp = endTimestamp_;
        duration = duration_;
    }

    function getAllMintPerSecond() external view returns (uint256, uint256) {
        return (getHubMintPerSecond(), getTreasuryMintPerSecond());
    }

    function getHubMintPerSecond() public view returns (uint256) {
        if (block.timestamp > endTimestamp) {
            return 0;
        }
        return (_mintPerSecond * (endTimestamp - block.timestamp) / duration);
    }

    function getTreasuryMintPerSecond() public view returns (uint256) {
        if (block.timestamp > endTimestamp) {
            return 0;
        }
        return (_mintPerSecond * (endTimestamp - block.timestamp) / duration);
    }
}
