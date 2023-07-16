// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";

/// @title Polygon Migration
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice This is the migration contract for Matic -> Polygon ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $MATIC into $POL and burns it
/// @custom:security-contact security@polygon.technology
contract PolygonMigration is Ownable2Step {
    using SafeERC20 for IERC20;

    IERC20 public immutable polygon;
    IERC20 public immutable matic;
    uint256 public releaseTimestamp;

    event Migrated(address indexed account, uint256 amount);

    constructor(IERC20 polygon_, IERC20 matic_, address owner_) {
        polygon = polygon_;
        matic = matic_;
        releaseTimestamp = block.timestamp + (365 days * 4); // 4 years
        _transferOwnership(owner_);
    }

    /// @notice This function allows for migrating MATIC tokens to POL tokens
    /// @dev The function does not do any validation since the migration is a one-way process
    /// @param amount Amount of MATIC to migrate
    function migrate(uint256 amount) external {
        emit Migrated(msg.sender, amount);

        matic.safeTransferFrom(msg.sender, address(this), amount);
        polygon.safeTransfer(msg.sender, amount);
        matic.safeTransfer(0x000000000000000000000000000000000000dEaD, amount);
    }

    /// @notice Allows governance to update the release timestamp if required
    /// @dev The function does not do any validation since governance can correct the timestamp if required
    /// @param timestamp_ New release timestamp
    function updateReleaseTimestamp(uint256 timestamp_) external onlyOwner {
        require(timestamp_ >= block.timestamp, "PolygonMigration: invalid timestamp");
        releaseTimestamp = timestamp_;
    }

    /// @notice Allows governance to release the remaining POL tokens after the migration period has elapsed
    function release() external onlyOwner {
        require(block.timestamp >= releaseTimestamp, "PolygonMigration: migration is not over");
        polygon.safeTransfer(msg.sender, polygon.balanceOf(address(this)));
    }
}
