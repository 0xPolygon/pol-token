# IDefaultEmissionManager
[Git Source](https://github.com/0xPolygon/pol-token/blob/7a1dec282d430e9f94fc81b42f7da0c058e0221b/src/interfaces/IDefaultEmissionManager.sol)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)

A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1

*The contract allows for a 3% mint per year (compounded). 2% staking layer and 1% treasury*


## Functions
### mint

allows anyone to mint tokens to the stakeManager and treasury contracts based on current emission rates

*minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any previous mints) and the newSupply (calculated based on the time elapsed since deployment)*


```solidity
function mint() external;
```

### INTEREST_PER_YEAR_LOG2


```solidity
function INTEREST_PER_YEAR_LOG2() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|log2(3%pa continuously compounded emission per year) in 18 decimals, see _inflatedSupplyAfter|


### START_SUPPLY


```solidity
function START_SUPPLY() external view returns (uint256);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`uint256`|the start supply of the POL token in 18 decimals|


### token


```solidity
function token() external view returns (IPolygonEcosystemToken polygonEcosystemToken);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`polygonEcosystemToken`|`IPolygonEcosystemToken`|address of the POL token|


### startTimestamp


```solidity
function startTimestamp() external view returns (uint256 timestamp);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`timestamp`|`uint256`|timestamp of initialisation of the contract, when emission starts|


### inflatedSupplyAfter

returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)

*interestRatePerYear = 1.03; 3% per year
approximate the compounded interest rate using x^y = 2^(log2(x)*y)
where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
log2(interestRatePerYear) = 0.04264433740849372 with 18 decimals, as the interest rate does not change, hard code the value*


```solidity
function inflatedSupplyAfter(uint256 timeElapsedInSeconds) external pure returns (uint256 inflatedSupply);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`timeElapsedInSeconds`|`uint256`|the time elapsed since startTimestamp|

**Returns**

|Name|Type|Description|
|----|----|-----------|
|`inflatedSupply`|`uint256`|supply total supply from compounded emission after timeElapsed|


### getVersion

returns the version of the contract


```solidity
function getVersion() external pure returns (string memory version);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`version`|`string`|version string|


## Events
### TokenMint
emitted when new tokens are minted


```solidity
event TokenMint(uint256 amount, address caller);
```

## Errors
### InvalidAddress
thrown when a zero address is supplied during deployment


```solidity
error InvalidAddress();
```

