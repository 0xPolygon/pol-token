# IPolygonMigration
[Git Source](https://github.com/0xPolygon/pol-token/blob/c05c8984ac856501829862c1f6d199208aa77a8e/src/interfaces/IPolygonMigration.sol)


## Functions
### unmigrationLocked


```solidity
function unmigrationLocked() external view returns (bool isUnmigrationLocked);
```

### getVersion


```solidity
function getVersion() external pure returns (string memory version);
```

### migrate


```solidity
function migrate(uint256 amount) external;
```

### unmigrate


```solidity
function unmigrate(uint256 amount) external;
```

### unmigrateTo


```solidity
function unmigrateTo(address recipient, uint256 amount) external;
```

### unmigrateWithPermit


```solidity
function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
```

### updateUnmigrationLock


```solidity
function updateUnmigrationLock(bool unmigrationLocked_) external;
```

### burn


```solidity
function burn(uint256 amount) external;
```

## Events
### Migrated

```solidity
event Migrated(address indexed account, uint256 amount);
```

### Unmigrated

```solidity
event Unmigrated(address indexed account, address indexed recipient, uint256 amount);
```

### UnmigrationLockUpdated

```solidity
event UnmigrationLockUpdated(bool lock);
```

## Errors
### UnmigrationLocked

```solidity
error UnmigrationLocked();
```

### InvalidAddressOrAlreadySet

```solidity
error InvalidAddressOrAlreadySet();
```

### InvalidAddress

```solidity
error InvalidAddress();
```

