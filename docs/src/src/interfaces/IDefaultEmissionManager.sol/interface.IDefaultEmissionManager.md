# IDefaultEmissionManager
[Git Source](https://github.com/0xPolygon/pol-token/blob/a780764684dd1ef1ca70707f8069da35cddbd074/src/interfaces/IDefaultEmissionManager.sol)


## Functions
### getVersion


```solidity
function getVersion() external pure returns (string memory version);
```

### token


```solidity
function token() external view returns (IPolygonEcosystemToken polygonEcosystemToken);
```

### startTimestamp


```solidity
function startTimestamp() external view returns (uint256 timestamp);
```

### mint


```solidity
function mint() external;
```

### inflatedSupplyAfter


```solidity
function inflatedSupplyAfter(uint256 timeElapsedInSeconds) external pure returns (uint256 inflatedSupply);
```

## Events
### TokenMint

```solidity
event TokenMint(uint256 amount, address caller);
```

## Errors
### InvalidAddress

```solidity
error InvalidAddress();
```

