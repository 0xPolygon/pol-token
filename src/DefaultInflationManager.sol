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
    uint256 public hubMintPerSecond;
    uint256 public treasuryMintPerSecond;
    uint256 public lastMint;
    uint256 public inflationModificationTimestamp;
    uint256 private _inflation_lock = 1;

    constructor(IPolygon token_, address hub_, address treasury_, address owner_) {
        token = token_;
        hub = hub_;
        treasury = treasury_;
        lastMint = block.timestamp;
        inflationModificationTimestamp = block.timestamp + (365 days * 10);
        _transferOwnership(owner_);
    }

    function mint() public {
        require(_inflation_lock == 1, "InflationManager: inflation is locked");
        uint256 amount = (block.timestamp - lastMint) * _mintPerSecond;
        lastMint = block.timestamp;
        token.mint(hub, amount);
        token.mint(treasury, amount);
    }

    function mintAfterUnlock() external {
        require(_inflation_lock == 0, "InflationManager: inflation is unlocked");
        uint256 _lastMint = lastMint;
        uint256 hubAmt = (block.timestamp - _lastMint) * hubMintPerSecond;
        uint256 treasuryAmt = (block.timestamp - _lastMint) * treasuryMintPerSecond;
        lastMint = block.timestamp;
        token.mint(hub, hubAmt);
        token.mint(treasury, treasuryAmt);
    }

    function updateHubMintPerSecond(uint256 hubMintPerSecond_) external onlyOwner {
        hubMintPerSecond = hubMintPerSecond_;
    }

    function updateTreasuryMintPerSecond(uint256 treasuryMintPerSecond_) external onlyOwner {
        treasuryMintPerSecond = treasuryMintPerSecond_;
    }

    function updateInflationModificationTimestamp(uint256 timestamp) external onlyOwner {
        require(timestamp >= block.timestamp, "InflationManager: invalid timestamp");
        inflationModificationTimestamp = timestamp;
    }

    function unlockInflationModification() external {
        require(
            block.timestamp >= inflationModificationTimestamp,
            "DefaultInflationManager: inflation modification is locked"
        );
        delete inflationModificationTimestamp;
        mint();
        delete _inflation_lock;
        hubMintPerSecond = treasuryMintPerSecond = _mintPerSecond;
    }
}
