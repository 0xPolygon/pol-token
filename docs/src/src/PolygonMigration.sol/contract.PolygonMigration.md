# PolygonMigration
[Git Source](https://github.com/0xPolygon/pol-token/blob/a780764684dd1ef1ca70707f8069da35cddbd074/src/PolygonMigration.sol)

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
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


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

This function allows for migrating MATIC tokens to POL tokens

*The function does not do any validation since the migration is a one-way process*


```solidity
function migrate(uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of MATIC to migrate|


### unmigrate

This function allows for unmigrating from POL tokens to MATIC tokens

*The function can only be called when unmigration is unlocked (lock updatable by governance)*

*The function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrate(uint256 amount) external onlyUnmigrationUnlocked;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of POL to migrate|


### unmigrateTo

This function allows for unmigrating POL tokens (from msg.sender) to MATIC tokens (to account)

*The function can only be called when unmigration is unlocked (lock updatable by governance)*

*The function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrateTo(address recipient, uint256 amount) external onlyUnmigrationUnlocked;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`recipient`|`address`|Address to receive MATIC tokens|
|`amount`|`uint256`|Amount of POL to migrate|


### unmigrateWithPermit

This function allows for unmigrating from POL tokens to MATIC tokens using an EIP-2612 permit

*The function can only be called when unmigration is unlocked (lock updatable by governance)*

*The function does not do any further validation, also note the unmigration is a reversible process*


```solidity
function unmigrateWithPermit(uint256 amount, uint256 deadline, uint8 v, bytes32 r, bytes32 s)
    external
    onlyUnmigrationUnlocked;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of POL to migrate|
|`deadline`|`uint256`|Deadline for the permit|
|`v`|`uint8`|v value of the permit signature|
|`r`|`bytes32`|r value of the permit signature|
|`s`|`bytes32`|s value of the permit signature|


### updateUnmigrationLock

Allows governance to lock or unlock the unmigration process

*The function does not do any validation since governance can update the unmigration process if required*


```solidity
function updateUnmigrationLock(bool unmigrationLocked_) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`unmigrationLocked_`|`bool`|New unmigration lock status|


### getVersion

Returns the implementation version


```solidity
function getVersion() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version string|


### burn

Allows governance to burn `amount` of POL tokens

*This functions burns POL by sending to dead address*

*does not change totalSupply in the internal accounting of POL*


```solidity
function burn(uint256 amount) external onlyOwner;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`amount`|`uint256`|Amount of POL to burn|


