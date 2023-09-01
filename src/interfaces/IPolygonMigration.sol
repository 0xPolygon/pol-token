// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPolygonMigration {
    error UnmigrationLocked();
    error InvalidAddressOrAlreadySet();
    error InvalidAddress();

    event Migrated(address indexed account, uint256 amount);
    event Unmigrated(address indexed account, uint256 amount);
    event UnmigrationLockUpdated(bool lock);

    function migrate(uint256 amount) external;

    function unmigrate(uint256 amount) external;

    function unmigrateTo(address account, uint256 amount) external;

    function unmigrateWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
