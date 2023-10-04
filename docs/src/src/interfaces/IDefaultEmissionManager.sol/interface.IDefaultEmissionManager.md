# IDefaultEmissionManager
[Git Source](https://github.com/0xPolygon/pol-token/blob/c05c8984ac856501829862c1f6d199208aa77a8e/src/interfaces/IDefaultEmissionManager.sol)


## Functions
### getVersion


```solidity
function getVersion() external pure returns (string memory version);
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

