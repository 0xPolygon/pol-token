# IPolygonEcosystemToken
[Git Source](https://github.com/0xPolygon/pol-token/blob/a780764684dd1ef1ca70707f8069da35cddbd074/src/interfaces/IPolygonEcosystemToken.sol)

**Inherits:**
IERC20, IERC20Permit, IAccessControlEnumerable


## Functions
### mintPerSecondCap


```solidity
function mintPerSecondCap() external view returns (uint256 currentMintPerSecondCap);
```

### getVersion


```solidity
function getVersion() external pure returns (string memory version);
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

