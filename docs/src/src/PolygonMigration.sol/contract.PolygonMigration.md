# PolygonMigration
[Git Source](https://github.com/0xPolygon/pol-token/blob/59aa38c99af46d3b365ecc8a7e9d0765591960b9/src/PolygonMigration.sol)

**Inherits:**
Ownable2StepUpgradeable, [IPolygonMigration](/src/interfaces/IPolygonMigration.sol/interface.IPolygonMigration.md)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk)

This is the migration contract for Matic <-> Polygon ERC20 token on Ethereum L1

*The contract allows for a 1-to-1 conversion from $MATIC into $POL and vice-versa*


## State Variables
### matic

```solidity
IERC20 public immutable matic;
```


### polygon

```solidity
IERC20 public polygon;
```


### unmigrationLocked

```solidity
bool public unmigrationLocked;
```


### __gap

```solidity
uint256[49] private __gap;
```


## Functions
### onlyUnmigrationUnlocked


```solidity
modifier onlyUnmigrationUnlocked();
```

### constructor


```solidity
constructor(address matic_);
```

### initialize


```solidity
function initialize() external initializer;
```

### setPolygonToken

This function allows owner/governance to set POL token address *only once*


```solidity
function setPolygonToken(address polygon_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`polygon_`|`address`|Address of deployed POL token|


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


```solidity
function unmigrate(uint256 amount) external onlyUnmigrationUnlocked;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of POL to migrate|


### unmigrateTo

this function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)

*the function can only be called when unmigration is unlocked (lock updatable by governance)*


```solidity
function unmigrateTo(address recipient, uint256 amount) external onlyUnmigrationUnlocked;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|address to receive MATIC tokens|
|`amount`|`uint256`|amount of POL to migrate|


### unmigrateWithPermit

this function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit

*the function can only be called when unmigration is unlocked (lock updatable by governance)*


```solidity
function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
    onlyUnmigrationUnlocked;
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
function updateUnmigrationLock(bool unmigrationLocked_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unmigrationLocked_`|`bool`||


### version

returns the version of the contract


```solidity
function version() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|version version string|


### burn

allows governance to burn `amount` of POL tokens

*this functions burns POL by sending to dead address*


```solidity
function burn(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|amount of POL to burn|


