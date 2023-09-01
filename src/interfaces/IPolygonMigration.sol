// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

interface IPolygonMigration {
    error UnmigrationLocked();
    error InvalidAddressOrAlreadySet();
    error InvalidTimestamp();
    error MigrationNotOver();
    error InvalidAddress();

    event Migrated(address indexed account, uint256 amount);
    event Unmigrated(address indexed account, uint256 amount);
    event UnmigrationLockUpdated(uint256 lock);
    event ReleaseTimestampUpdated(uint256 timestamp);
    event Released(uint256 polAmount, uint256 maticAmount);

    function migrate(uint256 amount) external;

    function unmigrate(uint256 amount) external;

    function unmigrateTo(uint256 amount, address account) external;

    function unmigrateWithPermit(
        uint256 amount,
        uint256 deadline,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) external;
}
