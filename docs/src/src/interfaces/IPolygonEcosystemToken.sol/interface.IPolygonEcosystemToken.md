# IPolygonEcosystemToken
[Git Source](https://github.com/0xPolygon/pol-token/blob/4e60db3944f1f433beb163a74034e19c0fc68cf0/src/interfaces/IPolygonEcosystemToken.sol)

**Inherits:**
IERC20, IERC20Permit, IAccessControlEnumerable

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)

This is the Polygon ERC20 token contract on Ethereum L1

*The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based on hub and treasury requirements*


## Functions
### mint

mint token entrypoint for the emission manager contract

*The function only validates the sender, the emission manager is responsible for correctness*


```solidity
function mint(address to, uint256 amount) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|address to mint to|
|`amount`|`uint256`|amount to mint|


### updateMintCap

update the limit of tokens that can be minted per second


```solidity
function updateMintCap(uint256 newCap) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newCap`|`uint256`|the amount of tokens in 18 decimals as an absolute value|


### updatePermit2Allowance

manages the default max approval to the permit2 contract


```solidity
function updatePermit2Allowance(bool enabled) external;
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`enabled`|`bool`|If true, the permit2 contract has full approval by default, if false, it has no approval by default|


### EMISSION_ROLE


```solidity
function EMISSION_ROLE() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|the role that allows minting of tokens|


### CAP_MANAGER_ROLE


```solidity
function CAP_MANAGER_ROLE() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|the role that allows updating the mint cap|


### PERMIT2_REVOKER_ROLE


```solidity
function PERMIT2_REVOKER_ROLE() external view returns (bytes32);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`bytes32`|the role that allows revoking the permit2 approval|


### PERMIT2


```solidity
function PERMIT2() external view returns (address);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`address`|the address of the permit2 contract|


### mintPerSecondCap

*13.37 POL tokens per second. will limit emission in ~23 years*


```solidity
function mintPerSecondCap() external view returns (uint256 currentMintPerSecondCap);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`currentMintPerSecondCap`|`uint256`|the current amount of tokens that can be minted per second|


### lastMint


```solidity
function lastMint() external view returns (uint256 lastMintTimestamp);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`lastMintTimestamp`|`uint256`|the timestamp of the last mint|


### permit2Enabled


```solidity
function permit2Enabled() external view returns (bool isPermit2Enabled);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`isPermit2Enabled`|`bool`|whether the permit2 default approval is currently active|


### getVersion

returns the version of the contract

*this is to support our dev pipeline, and is present despite this contract not being behind a proxy*


```solidity
function getVersion() external pure returns (string memory version);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`version`|`string`|version string|


## Events
### MintCapUpdated
emitted when the mint cap is updated


```solidity
event MintCapUpdated(uint256 oldCap, uint256 newCap);
```

### Permit2AllowanceUpdated
emitted when the permit2 integration is enabled/disabled


```solidity
event Permit2AllowanceUpdated(bool enabled);
```

## Errors
### InvalidAddress
thrown when a zero address is supplied during deployment


```solidity
error InvalidAddress();
```

### MaxMintExceeded
thrown when the mint cap is exceeded


```solidity
error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);
```

