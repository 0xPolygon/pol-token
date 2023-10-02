# IPolygonEcosystemToken
[Git Source](https://github.com/0xPolygon/pol-token/blob/c05c8984ac856501829862c1f6d199208aa77a8e/src/interfaces/IPolygonEcosystemToken.sol)

**Inherits:**
IERC20, IERC20Permit, IAccessControlEnumerable


## Functions
### mintPerSecondCap


```solidity
function mintPerSecondCap() external view returns (uint256 currentMintPerSecondCap);
```

### lastMint


```solidity
function lastMint() external view returns (uint256 lastMintTimestamp);
```

### permit2Enabled


```solidity
function permit2Enabled() external view returns (bool isPermit2Enabled);
```

### mint


```solidity
function mint(address to, uint256 amount) external;
```

### updateMintCap


```solidity
function updateMintCap(uint256 newCap) external;
```

### updatePermit2Allowance


```solidity
function updatePermit2Allowance(bool enabled) external;
```

## Events
### MintCapUpdated

```solidity
event MintCapUpdated(uint256 oldCap, uint256 newCap);
```

### Permit2AllowanceUpdated

```solidity
event Permit2AllowanceUpdated(bool enabled);
```

## Errors
### InvalidAddress

```solidity
error InvalidAddress();
```

### MaxMintExceeded

```solidity
error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);
```

