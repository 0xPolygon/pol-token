// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IInflationManager} from "./interfaces/IInflationManager.sol";
import {IPolygon} from "./interfaces/IPolygon.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

contract DefaultInflationManager is Ownable2Step, IInflationManager {
    uint256 private constant _mintPerSecond = 3170979198376458650;
    IPolygon public immutable token;
    address public immutable hub;
    address public immutable treasury;
    uint256 public lastMint;

    constructor(IPolygon token_, address hub_, address treasury_, address owner_) {
        token = token_;
        hub = hub_;
        treasury = treasury_;
        lastMint = block.timestamp;
        _transferOwnership(owner_);
    }

    function mint() external {
        uint256 amount = (block.timestamp - lastMint) * _mintPerSecond;
        lastMint = block.timestamp;
        token.mint(hub, amount);
        token.mint(treasury, amount);
    }
}
