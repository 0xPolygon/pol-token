// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Votes.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

/// @custom:security-contact security@polygon.technology
contract Polygon is Ownable2Step, ERC20Permit {
    address public inflationManager;
    uint256 private immutable _mintPerSecond = 3170979198376458650;

    error Invalid(string msg);

    constructor(address migration_, address inflationManager_, address owner_)
        ERC20("Polygon", "POL")
        ERC20Permit("Polygon")
    {
        inflationManager = inflationManager_;
        _mint(migration_, 10_000_000_000e18);
        _transferOwnership(owner_);
    }

    function mint(address to, uint256 amount) external {
        require(msg.sender == inflationManager, "Polygon: only inflation manager can mint");
        _mint(to, amount);
    }

    function updateInflationManager(address inflationManager_) external onlyOwner {
        inflationManager = inflationManager_;
    }
}
