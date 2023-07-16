// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IInflationManager} from "./interfaces/IInflationManager.sol";
import {IPolygon} from "./interfaces/IPolygon.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {Initializable} from "open

/// @title Default Inflation Manager
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice A default inflation manager for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1% mint each per year to the hub and treasury contracts
/// @custom:security-contact security@polygon.technology
contract DefaultInflationManager is Ownable2Step, IInflationManager {
    uint256 private constant _mintPerSecond = 3170979198376458650;
    IPolygon public token;
    address public hub;
    address public treasury;
    uint256 public hubMintPerSecond;
    uint256 public treasuryMintPerSecond;
    uint256 public lastMint;
    uint256 public inflationModificationTimestamp;
    uint256 private _inflation_lock = 1;

    function initialize(IPolygon token_, address hub_, address treasury_, address owner_) {
        token = token_;
        hub = hub_;
        treasury = treasury_;
        lastMint = block.timestamp;
        inflationModificationTimestamp = block.timestamp + (365 days * 10);
        _transferOwnership(owner_);
    }

    /// @notice Allows anyone to mint tokens to the hub and treasury contracts
    /// @dev Minting is done based on timestamp diffs at a constant rate
    function mint() public {
        require(_inflation_lock == 1, "InflationManager: inflation is unlocked");
        uint256 amount = (block.timestamp - lastMint) * _mintPerSecond;
        lastMint = block.timestamp;
        token.mint(hub, amount);
        token.mint(treasury, amount);
    }

    /// @notice Allows anyone to mint tokens to the hub and treasury contracts after the inflation lock is removed
    /// @dev Minting is done based on timestamp diffs at the respective constant rate
    function mintAfterUnlock() external {
        require(_inflation_lock == 0, "InflationManager: inflation is locked");
        uint256 _lastMint = lastMint;
        uint256 hubAmt = (block.timestamp - _lastMint) * hubMintPerSecond;
        uint256 treasuryAmt = (block.timestamp - _lastMint) * treasuryMintPerSecond;
        lastMint = block.timestamp;
        token.mint(hub, hubAmt);
        token.mint(treasury, treasuryAmt);
    }

    /// @notice Allows governance to update the mint per second rate for the hub and treasury contracts
    /// @param hubMintPerSecond_ The new hub mint per second rate
    /// @param treasuryMintPerSecond_ The new treasury mint per second rate
    function updateInflationRates(uint256 hubMintPerSecond_, uint256 treasuryMintPerSecond_) external onlyOwner {
        require(
            hubMintPerSecond_ < _mintPerSecond && treasuryMintPerSecond_ < _mintPerSecond,
            "InflationManager: mint per second too high"
        );
        hubMintPerSecond = hubMintPerSecond_;
        treasuryMintPerSecond = treasuryMintPerSecond_;
    }

    /// @notice Allows governance to update the inflation unlock timestamp
    /// @param timestamp The new inflation unlock timestamp
    function updateInflationModificationTimestamp(uint256 timestamp) external onlyOwner {
        require(timestamp >= block.timestamp, "InflationManager: invalid timestamp");
        inflationModificationTimestamp = timestamp;
    }

    /// @notice Allows governance to unlock inflation modification if the timestamp has passed
    /// @dev The function will mint remaining tokens to the hub and treasury contracts and set the mint per second rates to the default
    function unlockInflationModification() external onlyOwner {
        require(
            block.timestamp >= inflationModificationTimestamp,
            "DefaultInflationManager: inflation modification is locked"
        );
        delete inflationModificationTimestamp;
        mint();
        delete _inflation_lock;
        hubMintPerSecond = treasuryMintPerSecond = _mintPerSecond;
    }


    uint256[50] __gap;
}
