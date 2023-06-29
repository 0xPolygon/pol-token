// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

/// @custom:security-contact security@polygon.technology
contract Polygon is Ownable2Step, ERC20Permit {
    address public hub;
    address public treasury;
    uint256 public lastHubMint;
    uint256 public lastTreasuryMint;
    uint256 public hubInflationRate;
    uint256 public treasuryInflationRate;
    uint256 public nextSupplyIncreaseTimestamp;
    uint256 public previousSupply;
    uint256 private constant _ONE_YEAR = 31536000;

    constructor(address migration_, address hub_, address treasury_, address owner_) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        hub = hub_;
        treasury = treasury_;
        lastHubMint = block.timestamp;
        lastTreasuryMint = block.timestamp;
        hubInflationRate = 1e3;
        treasuryInflationRate = 1e3;
        nextSupplyIncreaseTimestamp = block.timestamp + _ONE_YEAR;
        uint256 initialSupply = 10000000000e18;
        previousSupply = initialSupply;
        _mint(migration_, initialSupply);
        _transferOwnership(owner_);
    }

    function mintToHub() public {
        if (block.timestamp < nextSupplyIncreaseTimestamp) {
            uint256 timeDiff = block.timestamp - lastHubMint;
            lastHubMint = block.timestamp;
            _mint(hub, (timeDiff * previousSupply * hubInflationRate) / (_ONE_YEAR * 100 * 1e3));
        } else {
            _updateYearlyInflation();
        }
    }

    function mintToTreasury() public {
        if (block.timestamp < nextSupplyIncreaseTimestamp) {
            uint256 timeDiff = block.timestamp - lastTreasuryMint;
            lastTreasuryMint = block.timestamp;
            _mint(treasury, (timeDiff * previousSupply * treasuryInflationRate) / (_ONE_YEAR * 100 * 1e3));
        } else {
            _updateYearlyInflation();
        }
    }

    function _updateYearlyInflation() internal {
        uint256 _nextSupplyIncreaseTimestamp = nextSupplyIncreaseTimestamp;
        uint256 hubTimeDiff = _nextSupplyIncreaseTimestamp - lastHubMint;
        uint256 treasuryTimeDiff = _nextSupplyIncreaseTimestamp - lastTreasuryMint;
        uint256 _previousSupply = previousSupply;
        _mint(hub, (hubTimeDiff * _previousSupply) / (_ONE_YEAR * 100));
        _mint(treasury, (treasuryTimeDiff * _previousSupply) / (_ONE_YEAR * 100));
        lastHubMint = lastTreasuryMint = _nextSupplyIncreaseTimestamp;
        previousSupply = (_previousSupply * (100 + ((hubInflationRate + treasuryInflationRate) / 1e3))) / 100; // update yearly inflation rate
        nextSupplyIncreaseTimestamp = _nextSupplyIncreaseTimestamp + _ONE_YEAR;
    }

    function updateHubInflation(uint256 newRate) external onlyOwner {
        require(newRate < hubInflationRate, "Polygon: inflation rate must be less than previous");
        hubInflationRate = newRate;
    }

    function updateTreasuryInflation(uint256 newRate) external onlyOwner {
        require(newRate < treasuryInflationRate, "Polygon: inflation rate must be less than previous");
        treasuryInflationRate = newRate;
    }
}
