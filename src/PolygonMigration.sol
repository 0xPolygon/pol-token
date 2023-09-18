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

    IERC20 public polygon;
    IERC20 public matic;
    bool public unmigrationLocked;

    modifier onlyUnmigrationUnlocked() {
        if (unmigrationLocked) revert UnmigrationLocked();
        _;
    }

    constructor() {
        // so that the implementation contract cannot be initialized
        _disableInitializers();
    }

    function initialize(address matic_) external initializer {
        __Ownable_init();
        if (matic_ == address(0)) revert InvalidAddress();
        matic = IERC20(matic_);
    }

    /// @notice This function allows owner/governance to set POL token address *only once*
    /// @param polygon_ Address of deployed POL token
    function setPolygonToken(address polygon_) external onlyOwner {
        if (polygon_ == address(0) || address(polygon) != address(0)) revert InvalidAddressOrAlreadySet();
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
    /// @dev The function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev The function does not do any further validation, also note the unmigration is a reversible process
    /// @param amount Amount of POL to migrate
    function unmigrate(uint256 amount) external onlyUnmigrationUnlocked {
        emit Unmigrated(msg.sender, msg.sender, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(msg.sender, amount);
    }

    /// @notice This function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)
    /// @dev The function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev The function does not do any further validation, also note the unmigration is a reversible process
    /// @param recipient Address to receive MATIC tokens
    /// @param amount Amount of POL to migrate
    function unmigrateTo(address recipient, uint256 amount) external onlyUnmigrationUnlocked {
        emit Unmigrated(msg.sender, recipient, amount);

        polygon.safeTransferFrom(msg.sender, address(this), amount);
        matic.safeTransfer(recipient, amount);
    }

    /// @notice This function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit
    /// @dev The function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev The function does not do any further validation, also note the unmigration is a reversible process
    /// @param amount Amount of POL to migrate
    /// @param deadline Deadline for the permit
    /// @param v v value of the permit signature
    /// @param r r value of the permit signature
    /// @param s s value of the permit signature
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

    /// @notice Allows governance to lock or unlock the unmigration process
    /// @dev The function does not do any validation since governance can update the unmigration process if required
    /// @param unmigrationLocked_ New unmigration lock status
    function updateUnmigrationLock(bool unmigrationLocked_) external onlyOwner {
        unmigrationLocked = unmigrationLocked_;
        emit UnmigrationLockUpdated(unmigrationLocked_);
    }

    /// @notice Returns the implementation version
    /// @return Version string
    function getVersion() external pure returns(string memory) {
        return "1.0.0";
    }

    /// @notice Allows governance to burn `amount` of POL tokens
    /// @dev This functions burns POL by sending to dead address
    /// @dev does not change totalSupply in the internal accounting of POL
    /// @param amount Amount of POL to burn
    function burn(uint256 amount) external onlyOwner {
        polygon.safeTransfer(0x000000000000000000000000000000000000dEaD, amount);
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
