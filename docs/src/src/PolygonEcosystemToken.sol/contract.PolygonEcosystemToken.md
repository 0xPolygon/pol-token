# PolygonEcosystemToken
[Git Source](https://github.com/0xPolygon/pol-token/blob/a780764684dd1ef1ca70707f8069da35cddbd074/src/PolygonEcosystemToken.sol)

**Inherits:**
ERC20Permit, AccessControlEnumerable, [IPolygonEcosystemToken](/src/interfaces/IPolygonEcosystemToken.sol/interface.IPolygonEcosystemToken.md)

**Author:**
Polygon Labs (@DhairyaSethi, @gretzke, @qedk)

This is the Polygon ERC20 token contract on Ethereum L1

*The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based on hub and treasury requirements*


## State Variables
### EMISSION_ROLE

```solidity
bytes32 public constant EMISSION_ROLE = keccak256("EMISSION_ROLE");
```


### CAP_MANAGER_ROLE

```solidity
bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE");
```


### PERMIT2_REVOKER_ROLE

```solidity
bytes32 public constant PERMIT2_REVOKER_ROLE = keccak256("PERMIT2_REVOKER_ROLE");
```


### PERMIT2

```solidity
address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
```


### mintPerSecondCap

```solidity
uint256 public mintPerSecondCap = 10e18;
```


### lastMint

```solidity
uint256 public lastMint;
```


### permit2Enabled

```solidity
bool public permit2Enabled;
```


## Functions
### constructor


```solidity
constructor(address migration, address emissionManager, address governance, address permit2Revoker)
    ERC20("Polygon Ecosystem Token", "POL")
    ERC20Permit("Polygon Ecosystem Token");
```

### mint

Mint token entrypoint for the emission manager contract

*The function only validates the sender, the emission manager is responsible for correctness*


```solidity
function mint(address to, uint256 amount) external onlyRole(EMISSION_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`to`|`address`|Address to mint to|
|`amount`|`uint256`|Amount to mint|


### updateMintCap

Update the limit of tokens that can be minted per second


```solidity
function updateMintCap(uint256 newCap) external onlyRole(CAP_MANAGER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`newCap`|`uint256`|the amount of tokens in 18 decimals as an absolute value|


### updatePermit2Allowance

Manages the default max approval to the permit2 contract


```solidity
function updatePermit2Allowance(bool enabled) external onlyRole(PERMIT2_REVOKER_ROLE);
```
**Parameters**

|Name|Type|Description|
|----|----|-----------|
|`enabled`|`bool`|If true, the permit2 contract has full approval by default, if false, it has no approval by default|


### allowance

The permit2 contract has full approval by default. If the approval is revoked, it can still be manually approved.


```solidity
function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256);
```

### getVersion

Returns the implementation version

*This is to support our dev pipeline, and is present despite
this contract not being behind a proxy*


```solidity
function getVersion() external pure returns (string memory);
```
**Returns**

|Name|Type|Description|
|----|----|-----------|
|`<none>`|`string`|Version string|


### _updatePermit2Allowance


```solidity
function _updatePermit2Allowance(bool enabled) private;
```

