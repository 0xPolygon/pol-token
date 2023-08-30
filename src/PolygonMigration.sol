// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2Step} from "openzeppelin-contracts/contracts/access/Ownable2Step.sol";
import {IPolygonMigration} from "./interfaces/IPolygonMigration.sol";

/// @title Polygon Migration
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa
/// @custom:security-contact security@polygon.technology
contract PolygonMigration is Ownable2Step, IPolygonMigration {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    IERC20 public polygon;
    IERC20 public immutable matic;
    uint256 public releaseTimestamp;
    uint256 public unmigrationLock;

    event Migrated(address indexed account, uint256 amount);
    event Unmigrated(address indexed account, uint256 amount);

    modifier ifUnmigrationUnlocked() {
        if (unmigrationLock != 0) revert UnmigrationLocked();
        _;
    }

    constructor(address matic_, address owner_) {
        matic = IERC20(matic_);
        releaseTimestamp = block.timestamp + (365 days * 4); // 4 years

        _transferOwnership(owner_);
    }

    /// @notice This function allows owner/governance to set POL token address *only once*
    /// @param polygon_ Address of deployed POL token
    function setPolygonToken(address polygon_) external onlyOwner {
        if (polygon_ == address(0) || address(polygon) != address(0))
            revert InvalidAddressOrAlreadySet();
        polygon = IERC20(polygon_);
    }

    /// @notice This function allows for migrating MATIC tokens to POL tokens
    /// @dev The function does not do any validation since the migration is a one-way process
    /// @param amount Amount of MATIC to migrate
    function migrate(uint256 amount) external {
        emit Migrated(msg.sender, amount);

        matic.safeTransferFrom(msg.sender, address(this), amount);
        polygon.safeTransfer(msg.sender, amount);
    }

    /// @notice This function allows for unmigrating from POL tokens to MATIC tokens
    /// @param amount Amount of POL to migrate
    function unmigrate(uint256 amount) external ifUnmigrationUnlocked {
        emit Unmigrated(msg.sender, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(msg.sender, amount);
    }

    /// @notice This function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)
    /// @param amount Amount of POL to migrate
    /// @param account Address to receive MATIC tokens
    function unmigrateTo(
        uint256 amount,
        address account
    ) external ifUnmigrationUnlocked {
        emit Unmigrated(msg.sender, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(account, amount);
    }

    /// @notice This function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit
    /// @param amount Amount of POL to migrate
    function unmigrateWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external ifUnmigrationUnlocked {
        emit Unmigrated(msg.sender, amount);

        IERC20Permit(address(polygon)).safePermit(
            msg.sender,
            address(this),
            amount,
            deadline,
            v,
            r,
            s
        );
        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(msg.sender, amount);
    }

    /// @notice Allows governance to update the release timestamp if required
    /// @dev The function does not do any validation since governance can correct the timestamp if required
    /// @param timestamp_ New release timestamp
    function updateReleaseTimestamp(uint256 timestamp_) external onlyOwner {
        if (timestamp_ < block.timestamp) revert InvalidTimestamp();
        releaseTimestamp = timestamp_;
    }

    /// @notice Allows governance to lock or unlock the unmigration process
    /// @dev The function does not do any validation since governance can update the unmigration process if required
    /// @param unmigrationLock_ New unmigration lock status
    function updateUnmigrationLock(
        uint256 unmigrationLock_
    ) external onlyOwner {
        unmigrationLock = unmigrationLock_;
    }

    /// @notice Allows governance to release the remaining POL tokens after the migration period has elapsed
    /// @dev In case any MATIC was sent out of process, it will be sent to the dead address
    function release() external onlyOwner {
        if (block.timestamp < releaseTimestamp) revert MigrationNotOver();
        polygon.safeTransfer(msg.sender, polygon.balanceOf(address(this)));
        matic.safeTransfer(
            0x000000000000000000000000000000000000dEaD,
            matic.balanceOf(address(this))
        );
    }
}
