# IPolygonMigration
[Git Source](https://github.com/0xPolygon/pol-token/blob/4e60db3944f1f433beb163a74034e19c0fc68cf0/src/interfaces/IPolygonMigration.sol)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk)

This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1

*The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa*


## Functions
### migrate

this function allows for migrating MATIC tokens to POL tokens

*the function does not do any validation since the migration is a one-way process*


```solidity
function migrate(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of MATIC to migrate|


### unmigrate

this function allows for unmigrating from POL tokens to MATIC tokens

*the function can only be called when unmigration is unlocked (lock updatable by governance)*

*the function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrate(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of POL to migrate|


### unmigrateTo

this function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)

*the function can only be called when unmigration is unlocked (lock updatable by governance)*

*the function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrateTo(address recipient, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|address to receive MATIC tokens|
|`amount`|`uint256`|amount of POL to migrate|


### unmigrateWithPermit

this function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit

*the function can only be called when unmigration is unlocked (lock updatable by governance)*

*the function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of POL to migrate|
|`deadline`|`uint256`|deadline for the permit|
|`v`|`uint8`|v value of the permit signature|
|`r`|`bytes32`|r value of the permit signature|
|`s`|`bytes32`|s value of the permit signature|


### updateUnmigrationLock

allows governance to lock or unlock the unmigration process

*the function does not do any validation since governance can update the unmigration process if required*


```solidity
function updateUnmigrationLock(bool unmigrationLocked) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unmigrationLocked`|`bool`|new unmigration lock status|


### burn

allows governance to burn `amount` of POL tokens

*this functions burns POL by sending to dead address*

*does not change totalSupply in the internal accounting of POL*


```solidity
function burn(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of POL to burn|


### matic


```solidity
function matic() external view returns (IERC20 maticToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`maticToken`|`IERC20`|the MATIC token address|


### polygon


```solidity
function polygon() external view returns (IERC20 polygonEcosystemToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`polygonEcosystemToken`|`IERC20`|the POL token address|


### unmigrationLocked


```solidity
function unmigrationLocked() external view returns (bool isUnmigrationLocked);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isUnmigrationLocked`|`bool`|whether the unmigration is locked or not|


### getVersion


```solidity
function getVersion() external pure returns (string memory version);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`version`|`string`|the implementation version|


## Events
### Migrated
emitted when MATIC are migrated to POL


```solidity
event Migrated(address indexed account, uint256 amount);
```

### Unmigrated
emitted when POL are unmigrated to MATIC


```solidity
event Unmigrated(address indexed account, address indexed recipient, uint256 amount);
```

### UnmigrationLockUpdated
emitted when the unmigration is enabled/disabled


```solidity
event UnmigrationLockUpdated(bool lock);
```

## Errors
### UnmigrationLocked
thrown when a user attempts to unmigrate while unmigration is locked


```solidity
error UnmigrationLocked();
```

### InvalidAddressOrAlreadySet
thrown when an invalid POL token address is supplied or the address is already set


```solidity
error InvalidAddressOrAlreadySet();
```

### InvalidAddress
thrown when a zero address is supplied during deployment


```solidity
error InvalidAddress();
```

