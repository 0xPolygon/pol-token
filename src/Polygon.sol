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
    uint256 public previousSupply = 10000000000;
    uint256 private constant ONE_YEAR = 31536000;

    constructor(address migration_, address hub_, address treasury_) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        hub = hub_;
        treasury = treasury_;
        lastHubMint = block.timestamp;
        lastTreasuryMint = block.timestamp;
        nextSupplyIncreaseTimestamp = block.timestamp + ONE_YEAR;
        _mint(migration_, previousSupply * 10 ** decimals());
    }

    function mintToHub() external {
        uint256 timeDiff = block.timestamp - lastHubMint;
        lastHubMint = block.timestamp;
        uint256 amount = (timeDiff * previousSupply) / (ONE_YEAR * 100);
        // prevent moving forward timestamp when no tokens are claimable
        require(amount != 0, "Polygon: minting not allowed yet");
        _mint(hub, amount);
        _updatePreviousSupply();
    }

    function mintToTreasury() external {
        uint256 timeDiff = block.timestamp - lastTreasuryMint;
        lastTreasuryMint = block.timestamp;
        uint256 amount = (timeDiff * previousSupply) / (ONE_YEAR * 100);
        // prevent moving forward mint timestamp when no tokens are claimable
        require(amount != 0, "Polygon: minting not allowed yet");
        _mint(treasury, amount);
        _updatePreviousSupply();
    }

    function _updatePreviousSupply() private {
        unchecked { // no need to check for overflow
            if (block.timestamp >= nextSupplyIncreaseTimestamp) {
                previousSupply = (previousSupply * 102) / 100;
                nextSupplyIncreaseTimestamp += ONE_YEAR;
            }
        }
    }
}
