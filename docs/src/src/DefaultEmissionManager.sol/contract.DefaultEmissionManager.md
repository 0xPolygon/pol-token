# DefaultEmissionManager
[Git Source](https://github.com/0xPolygon/pol-token/blob/a780764684dd1ef1ca70707f8069da35cddbd074/src/DefaultEmissionManager.sol)

**Inherits:**
Ownable2StepUpgradeable, [IDefaultEmissionManager](/src/interfaces/IDefaultEmissionManager.sol/interface.IDefaultEmissionManager.md)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk)

A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1

*The contract allows for a 1% mint *each* per year (compounded every year) to the stakeManager and treasury contracts*


## State Variables
### INTEREST_PER_YEAR_LOG2

```solidity
uint256 public constant INTEREST_PER_YEAR_LOG2 = 0.028569152196770894e18;
```


### START_SUPPLY

```solidity
uint256 public constant START_SUPPLY = 10_000_000_000e18;
```


### DEPLOYER

```solidity
address private immutable DEPLOYER;
```


### migration

```solidity
IPolygonMigration public immutable migration;
```


### stakeManager

```solidity
address public immutable stakeManager;
```


### treasury

```solidity
address public immutable treasury;
```


### token

```solidity
IPolygonEcosystemToken public token;
```


### startTimestamp

```solidity
uint256 public startTimestamp;
```


### __gap
*This empty reserved space is put in place to allow future versions to add new
variables without shifting down storage in the inheritance chain.
See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps*


```solidity
uint256[48] private __gap;
```


## Functions
### constructor


```solidity
constructor(address migration_, address stakeManager_, address treasury_);
```

### initialize


```solidity
function initialize(address token_, address owner_) external initializer;
```

### mint

Allows anyone to mint tokens to the stakeManager and treasury contracts based on current emission rates

*Minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any
previous mints) and the newSupply (calculated based on the time elapsed since deployment)*


```solidity
function mint() external;
```

### inflatedSupplyAfter

Returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)

*interestRatePerYear = 1.02; 2% per year
approximate the compounded interest rate using x^y = 2^(log2(x)*y)
where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
log2(interestRatePerYear) = 0.028569152196770894 with 18 decimals, as the interest rate does not change, hard code the value*


```solidity
function inflatedSupplyAfter(uint256 timeElapsed) public pure returns (uint256 supply);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timeElapsed`|`uint256`|The time elapsed since startTimestamp|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`supply`|`uint256`|total supply from compounded emission after timeElapsed|


### getVersion

Returns the implementation version


```solidity
function getVersion() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version string|


