// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @title Polygon Migration
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1
/// @dev The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa
/// @custom:security-contact security@polygon.technology
interface IPolygonMigration {
    /// @notice emitted when MATIC are migrated to POL
    /// @param account the account that migrated MATIC
    /// @param amount the amount of MATIC that was migrated
    event Migrated(address indexed account, uint256 amount);

    /// @notice emitted when POL are unmigrated to MATIC
    /// @param account the account that unmigrated POL
    /// @param recipient the account that received MATIC
    /// @param amount the amount of POL that was unmigrated
    event Unmigrated(address indexed account, address indexed recipient, uint256 amount);

    /// @notice emitted when the unmigration is enabled/disabled
    /// @param lock whether the unmigration is enabled or not
    event UnmigrationLockUpdated(bool lock);

    /// @notice thrown when a user attempts to unmigrate while unmigration is locked
    error UnmigrationLocked();

    /// @notice thrown when an invalid POL token address is supplied or the address is already set
    error InvalidAddressOrAlreadySet();

    /// @notice thrown when a zero address is supplied during deployment
    error InvalidAddress();

    /// @notice this function allows for migrating MATIC tokens to POL tokens
    /// @param amount amount of MATIC to migrate
    /// @dev the function does not do any validation since the migration is a one-way process
    function migrate(uint256 amount) external;

    /// @notice this function allows for unmigrating from POL tokens to MATIC tokens
    /// @param amount amount of POL to migrate
    /// @dev the function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev the function does not do any further validation, also note the unmigration is a reversible process
    function unmigrate(uint256 amount) external;

    /// @notice this function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)
    /// @param recipient address to receive MATIC tokens
    /// @param amount amount of POL to migrate
    /// @dev the function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev the function does not do any further validation, also note the unmigration is a reversible process
    function unmigrateTo(address recipient, uint256 amount) external;

    /// @notice this function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit
    /// @param amount amount of POL to migrate
    /// @param deadline deadline for the permit
    /// @param v v value of the permit signature
    /// @param r r value of the permit signature
    /// @param s s value of the permit signature
    /// @dev the function can only be called when unmigration is unlocked (lock updatable by governance)
    /// @dev the function does not do any further validation, also note the unmigration is a reversible process
    function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    /// @notice allows governance to lock or unlock the unmigration process
    /// @param unmigrationLocked new unmigration lock status
    /// @dev the function does not do any validation since governance can update the unmigration process if required
    function updateUnmigrationLock(bool unmigrationLocked) external;

    /// @notice allows governance to burn `amount` of POL tokens
    /// @param amount amount of POL to burn
    /// @dev this functions burns POL by sending to dead address
    /// @dev does not change totalSupply in the internal accounting of POL
    function burn(uint256 amount) external;

    /// @return maticToken the MATIC token address
    function matic() external view returns (IERC20 maticToken);

    /// @return polygonEcosystemToken the POL token address
    function polygon() external view returns (IERC20 polygonEcosystemToken);

    /// @return isUnmigrationLocked whether the unmigration is locked or not
    function unmigrationLocked() external view returns (bool isUnmigrationLocked);

    /// @notice returns the version of the contract
    /// @return version version string
    function version() external pure returns (string memory version);
}
