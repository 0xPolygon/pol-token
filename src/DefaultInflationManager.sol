// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IMinter} from "./interfaces/IMinter.sol";
import {IPolygon} from "./interfaces/IPolygon.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";

/// @title Default Inflation Manager
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice A default inflation manager implementation for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1% mint each per year to the hub and treasury contracts
/// @custom:security-contact security@polygon.technology
contract DefaultInflationManager is Initializable, Ownable2StepUpgradeable, IMinter {
    uint256 private constant _MINT_PER_SECOND = 3170979198376458650;
    IPolygon public token;
    address public hub;
    address public treasury;
    uint256 public hubMintPerSecond;
    uint256 public treasuryMintPerSecond;
    uint256 public lastMint;

    constructor() initializer {}

    function initialize(IPolygon token_, address hub_, address treasury_, address owner_) external initializer {
        token = token_;
        hub = hub_;
        treasury = treasury_;
        hubMintPerSecond = treasuryMintPerSecond = _MINT_PER_SECOND;
        lastMint = block.timestamp;
        _transferOwnership(owner_);
    }

    /// @notice Allows anyone to mint tokens to the hub and treasury contracts based on current inflation rates
    /// @dev Minting is done based on timestamp diffs at the respective constant rate
    function mint() external {
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
            hubMintPerSecond_ < _MINT_PER_SECOND && treasuryMintPerSecond_ < _MINT_PER_SECOND,
            "DefaultInflationManager: mint per second too high"
        );
        hubMintPerSecond = hubMintPerSecond_;
        treasuryMintPerSecond = treasuryMintPerSecond_;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
