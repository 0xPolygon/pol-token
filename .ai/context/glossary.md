# Glossary — pol-token

| Term | Definition |
|------|-----------|
| **POL** | Polygon Ecosystem Token — the ERC-20 token on Ethereum L1 that upgrades MATIC. Contract: `PolygonEcosystemToken.sol`. |
| **MATIC** | The legacy Polygon token on Ethereum. POL replaces it at a 1:1 ratio via the migration contract. |
| **Migration** | The 1:1 swap process from MATIC to POL, handled by `PolygonMigration.sol`. Users send MATIC and receive POL. |
| **Unmigration** | The reverse swap from POL back to MATIC. Can be permanently locked by governance via `updateUnmigrationLock()`. |
| **Emission** | The process of minting new POL tokens at a compounded annual rate. Currently set to 2% per year (changed from 3% in v1.4.0). |
| **Emission Manager** | `DefaultEmissionManager.sol` — the only contract holding `EMISSION_ROLE`. Calculates and distributes new token supply. |
| **StakeManager** | External Polygon staking contract that receives 50% of emissions (1% annual) as staking rewards. |
| **Treasury** | Community treasury address that receives 50% of emissions (1% annual) for ecosystem funding. |
| **Protocol Council** | Governance multisig (`0x37D0...5516`) holding `DEFAULT_ADMIN_ROLE`. Controls role assignments, mint cap, and proxy upgrades. |
| **Emergency Council** | Secondary governance multisig with `PERMIT2_REVOKER_ROLE` for urgent Permit2 actions. |
| **ProxyAdmin** | OpenZeppelin `ProxyAdmin` contract (`0xEBea...39c3`) that controls `TransparentUpgradeableProxy` upgrades for migration and emission manager. |
| **PIP** | Polygon Improvement Proposal. PIP-17 proposed the POL token; PIP-26 and PIP-41 relate to subsequent changes. |
| **mintPerSecondCap** | Rate limiter on `PolygonEcosystemToken.mint()`. Default: 13.37 POL/second. Prevents excessive minting even if the emission manager is compromised. |
| **Permit2** | Uniswap's universal token approval contract (`0x0000...8BA3`). POL grants it max allowance by default; this can be revoked by `PERMIT2_REVOKER_ROLE`. |
| **reinitializer** | OpenZeppelin pattern for running initialization logic during contract upgrades. Current version for `DefaultEmissionManager`: `reinitializer(3)`. Must be incremented for each upgrade that needs initialization. |
| **`__gap`** | Reserved storage slot array in upgradeable contracts. Preserves storage layout compatibility when new state variables are added in future versions. |
| **via-IR** | Solidity compiler option that compiles through the Yul intermediate representation. Enabled in `foundry.toml` for this project. Produces more optimized bytecode but increases compile time. |
| **START_SUPPLY** | Initial POL total supply: 10 billion tokens (10,000,000,000e18). Minted to the migration contract at deployment. |
| **START_SUPPLY_1_4_0** | Snapshot of `token.totalSupply()` taken at the v1.4.0 upgrade. Used as the base for emission calculations going forward. Overwrites a previous storage slot. |
