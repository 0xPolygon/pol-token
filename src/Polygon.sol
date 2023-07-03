// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, ERC20Permit, ERC20Votes} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Beneficiary, MintingManager} from "./lib/MintingManager.sol";

/// @custom:security-contact security@polygon.technology
contract Polygon is Ownable2Step, ERC20Votes {
    using MintingManager for Beneficiary;

    Beneficiary public hub;
    Beneficiary public treasury;

    constructor(
        address migration_,
        address hub_,
        address treasury_,
        address owner_
    ) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        uint256 initialSupply = 10_000_000_000e18; // 10 billion tokens
        _mint(migration_, initialSupply);
        hub = MintingManager.create(hub_, initialSupply / 100);
        treasury = MintingManager.create(treasury_, initialSupply / 100);
        _transferOwnership(owner_);
    }

    function mintToHub() public {
        uint256 amount = hub.claimMintedTokens();
        _mint(hub.addr(), amount);
    }

    function mintToTreasury() public {
        uint256 amount = treasury.claimMintedTokens();
        _mint(treasury.addr(), amount);
    }

    function updateHubInflation(uint256 newRate) external onlyOwner {
        hub.decreaseInflation(newRate);
    }

    function updateTreasuryInflation(uint256 newRate) external onlyOwner {
        treasury.decreaseInflation(newRate);
    }
}
