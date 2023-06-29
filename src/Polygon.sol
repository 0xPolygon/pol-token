// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact security@polygon.technology
contract Polygon is ERC20Permit {
    address public hub;
    address public treasury;
    uint256 public lastHubMint;
    uint256 public lastTreasuryMint;
    uint256 public nextSupplyIncreaseTimestamp;
    uint256 public previousSupply;
    uint256 private constant _ONE_YEAR = 31536000;

    constructor(address migration_, address hub_, address treasury_) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        hub = hub_;
        treasury = treasury_;
        lastHubMint = block.timestamp;
        lastTreasuryMint = block.timestamp;
        nextSupplyIncreaseTimestamp = block.timestamp + _ONE_YEAR;
        uint256 initialSupply = 10000000000e18;
        previousSupply = initialSupply;
        _mint(migration_, initialSupply);
    }

    function mintToHub() public {
        if (block.timestamp < nextSupplyIncreaseTimestamp) {
            uint256 timeDiff = block.timestamp - lastHubMint;
            lastHubMint = block.timestamp;
            _mint(hub, (timeDiff * previousSupply) / (_ONE_YEAR * 100));
        } else {
            _updateYearlyInflation();
        }
    }

    function mintToTreasury() public {
        if (block.timestamp < nextSupplyIncreaseTimestamp) {
            uint256 timeDiff = block.timestamp - lastTreasuryMint;
            lastTreasuryMint = block.timestamp;
            _mint(treasury, (timeDiff * previousSupply) / (_ONE_YEAR * 100));
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
        previousSupply = (_previousSupply * 102) / 100; // update yearly inflation rate
        nextSupplyIncreaseTimestamp = _nextSupplyIncreaseTimestamp + _ONE_YEAR;
    }
}
