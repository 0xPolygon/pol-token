// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";

/// @custom:security-contact security@polygon.technology
contract Polygon is ERC20Permit {
    address public hub;
    uint256 public lastMint;
    uint256 private constant ONE_YEAR = 31536000;

    constructor(address migration_, address hub_) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        hub = hub_;
        lastMint = block.timestamp;
        _mint(migration_, 10000000000 * 10 ** decimals());
        _mint(hub_, 100000000 * 10 ** decimals());
    }

    function mint() external {
        require(block.timestamp >= lastMint + ONE_YEAR, "Polygon: minting not allowed yet");
        lastMint += ONE_YEAR;
        _mint(hub, 1 * totalSupply() / 100);
    }
}
