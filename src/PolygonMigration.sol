// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {IPolygonMigration} from "./interfaces/IPolygonMigration.sol";

/// @title Polygon Migration
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa
/// @custom:security-contact security@polygon.technology
contract PolygonMigration is Ownable2StepUpgradeable, IPolygonMigration {
    using SafeERC20 for IERC20;
    using SafeERC20 for IERC20Permit;

    IERC20 public immutable matic;
    IERC20 public polygon;
    bool public unmigrationLocked;

    modifier onlyUnmigrationUnlocked() {
        if (unmigrationLocked) revert UnmigrationLocked();
        _;
    }

    constructor(address matic_) {
        if (matic_ == address(0)) revert InvalidAddress();
        matic = IERC20(matic_);
        // so that the implementation contract cannot be initialized
        _disableInitializers();
    }

    function initialize() external initializer {
        __Ownable_init();
    }

    /// @notice This function allows owner/governance to set POL token address *only once*
    /// @param polygon_ Address of deployed POL token
    function setPolygonToken(address polygon_) external onlyOwner {
        if (polygon_ == address(0) || address(polygon) != address(0)) revert InvalidAddressOrAlreadySet();
        polygon = IERC20(polygon_);
    }

    /// @inheritdoc IPolygonMigration
    function migrate(uint256 amount) external {
        emit Migrated(msg.sender, amount);

        matic.safeTransferFrom(msg.sender, address(this), amount);
        polygon.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IPolygonMigration
    function unmigrate(uint256 amount) external onlyUnmigrationUnlocked {
        emit Unmigrated(msg.sender, msg.sender, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IPolygonMigration
    function unmigrateTo(address recipient, uint256 amount) external onlyUnmigrationUnlocked {
        emit Unmigrated(msg.sender, recipient, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(recipient, amount);
    }

    /// @inheritdoc IPolygonMigration
    function unmigrateWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external onlyUnmigrationUnlocked {
        emit Unmigrated(msg.sender, msg.sender, amount);

        IERC20Permit(address(polygon)).safePermit(msg.sender, address(this), amount, deadline, v, r, s);
        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(msg.sender, amount);
    }

    /// @inheritdoc IPolygonMigration
    function updateUnmigrationLock(bool unmigrationLocked_) external onlyOwner {
        emit UnmigrationLockUpdated(unmigrationLocked_);
        unmigrationLocked = unmigrationLocked_;
    }

    /// @inheritdoc IPolygonMigration
    function version() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @inheritdoc IPolygonMigration
    function burn(uint256 amount) external onlyOwner {
        polygon.safeTransfer(0x000000000000000000000000000000000000dEaD, amount);
    }

    uint256[49] private __gap;
}
