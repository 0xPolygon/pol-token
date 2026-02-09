# Security Rules — pol-token

> These rules are **non-negotiable**. They reflect the security invariants of the deployed POL token system on Ethereum mainnet. Violations risk loss of funds or governance compromise.

## Access Control

- NEVER remove or weaken role-based access checks (`onlyRole`, `onlyOwner` modifiers).
- NEVER grant `EMISSION_ROLE` to any address other than the `DefaultEmissionManager` proxy.
- NEVER grant `DEFAULT_ADMIN_ROLE` to externally owned accounts (EOAs). It MUST remain with the Protocol Council multisig.
- ALWAYS use `Ownable2StepUpgradeable` (not `Ownable`) for upgradeable contracts to prevent accidental ownership transfers.
- NEVER add new privileged roles without governance approval.

## Token Minting

- NEVER bypass or increase `mintPerSecondCap` without governance approval.
- NEVER allow minting outside the emission manager flow (`EMISSION_ROLE` enforced on `PolygonEcosystemToken.mint()`).
- ALWAYS validate mint amounts against the time-based cap (`timeElapsed * mintPerSecondCap`).
- NEVER modify the emission rate constants (`INTEREST_PER_YEAR_LOG2`) without a PIP and governance vote.

## Upgrade Safety

- NEVER modify `immutable` variables in upgrade implementations (they are set in the constructor and stored in bytecode).
- ALWAYS call `_disableInitializers()` in implementation contract constructors to prevent direct initialization.
- ALWAYS increment `reinitializer` version numbers when adding new initialization logic. Current version: `reinitializer(3)`.
- NEVER change the storage layout order in upgradeable contracts. Respect the `__gap` array.
- ALWAYS adjust `__gap` size when adding new state variables (total slots must remain constant).
- NEVER remove the `DEPLOYER` check in `DefaultEmissionManager.initialize()` — it prevents front-running.

## Migration Safety

- NEVER allow re-setting the POL token address in `PolygonMigration` — `setPolygonToken()` is one-time only.
- NEVER remove the `unmigrationLocked` check from unmigration functions.
- ALWAYS maintain the 1:1 MATIC-to-POL conversion ratio.

## Cryptographic Safety

- NEVER weaken EIP-2612 permit/signature validation.
- ALWAYS use `SafeERC20` for all ERC-20 token transfers (prevents silent failures).
- NEVER modify the Permit2 integration in ways that bypass user consent.

## Deployment Safety

- NEVER include `--broadcast` in committed scripts or makefile targets by default.
- NEVER commit private keys, RPC URLs containing API keys, or `.env` files.
- ALWAYS use environment variables for secrets (`PRIVATE_KEY`, `RPC_URL`, `RPC_MAINNET`, `ETHERSCAN_API_KEY`).
- ALWAYS verify deployed contracts on Etherscan using `--verify`.

## Math Safety

- NEVER modify `PowUtil.exp2()` without understanding the fixed-point arithmetic and verifying against Certora specs.
- ALWAYS use `assertApproxEqAbs` with appropriate delta (1e13) when testing exponential calculations.
- NEVER introduce floating-point or unchecked arithmetic in emission calculations.
