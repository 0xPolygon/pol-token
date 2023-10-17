# DefaultEmissionManager
[Git Source](https://github.com/0xPolygon/pol-token/blob/4e60db3944f1f433beb163a74034e19c0fc68cf0/src/DefaultEmissionManager.sol)

**Inherits:**
Ownable2StepUpgradeable, [IDefaultEmissionManager](/src/interfaces/IDefaultEmissionManager.sol/interface.IDefaultEmissionManager.md)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)

A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1

*The contract allows for a 3% mint per year (compounded). 2% staking layer and 1% treasury*


## State Variables
### INTEREST_PER_YEAR_LOG2

```solidity
uint256 public constant INTEREST_PER_YEAR_LOG2 = 0.04264433740849372e18;
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

allows anyone to mint tokens to the stakeManager and treasury contracts based on current emission rates

*minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any previous mints) and the newSupply (calculated based on the time elapsed since deployment)*


```solidity
function mint() external;
```

### inflatedSupplyAfter

returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)

*interestRatePerYear = 1.03; 3% per year
approximate the compounded interest rate using x^y = 2^(log2(x)*y)
where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
log2(interestRatePerYear) = 0.04264433740849372 with 18 decimals, as the interest rate does not change, hard code the value*


```solidity
function inflatedSupplyAfter(uint256 timeElapsed) public pure returns (uint256 supply);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timeElapsed`|`uint256`||

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`supply`|`uint256`|inflatedSupply supply total supply from compounded emission after timeElapsed|


### getVersion

returns the version of the contract


```solidity
function getVersion() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|version version string|


