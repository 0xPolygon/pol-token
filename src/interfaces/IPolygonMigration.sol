// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

interface IPolygonMigration {
    error UnmigrationLocked();
    error InvalidAddressOrAlreadySet();
    error InvalidAddress();

    event Migrated(address indexed account, uint256 amount);
    event Unmigrated(address indexed account, address indexed recipient, uint256 amount);
    event UnmigrationLockUpdated(bool lock);

    function unmigrationLocked() external view returns (bool isUnmigrationLocked);

    function polygon() external view returns (IERC20 polygonEcosystemToken);

    function getVersion() external pure returns (string memory version);

    function migrate(uint256 amount) external;

    function unmigrate(uint256 amount) external;

    function unmigrateTo(address recipient, uint256 amount) external;

    function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;

    function updateUnmigrationLock(bool unmigrationLocked_) external;

    function burn(uint256 amount) external;
}
