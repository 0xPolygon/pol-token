# Testing Rules — pol-token

## Required Checks

Every PR MUST pass these checks before merge:

```bash
forge build       # Must compile with zero errors
forge test -vvv   # All tests must pass
```

## Test Conventions

- **Location:** All tests live in `test/`, named `<Contract>.t.sol`
- **Inheritance:** Test contracts inherit from `forge-std/Test.sol`
- **Setup:** Use `setUp()` for test fixture initialization (deploy contracts, set roles, fund accounts)
- **Naming:**
  - `test_<description>` or `test<Description>` — expected to pass
  - `testFail_<description>` — expected to revert (legacy pattern)
  - `testRevert_<description>` — expected to revert with specific error
  - `testFuzz_<description>(uint256 x)` — fuzz tests with random inputs

## Fork Tests

- Fork tests use `vm.createSelectFork()` with the `RPC_MAINNET` environment variable.
- ALWAYS pin fork tests to a specific block number for reproducibility.
- Fork tests are in `test/upgrade/` for upgrade validation.
- Example: `DefaultEmissionManager.1.4.0.mainnet.t.sol` tests the v1.4.0 upgrade against mainnet state.

## When to Write Tests

- Any new `public` or `external` function MUST have corresponding tests.
- Any bug fix MUST include a regression test that fails without the fix.
- Upgrade scripts MUST have fork-based upgrade tests pinned to a specific block.
- Changes to emission math MUST include precision tests using `assertApproxEqAbs` with 1e13 delta.

## Fuzz Testing

- **Default profile:** Standard Foundry fuzz run count.
- **Intense profile:** 10,000 fuzz runs — activate with `FOUNDRY_PROFILE=intense forge test -vvv`.
- Use the intense profile when modifying math-heavy code (PowUtil, emission calculations).

## Formal Verification

- Certora specifications exist in `certora/` with harnesses and configurations.
- NEVER modify Certora specs without understanding the verification context.
- If changing contract logic covered by Certora specs, flag this in the PR for reviewer attention.

## Test Utilities

- `test/util/` contains shared test helpers.
- `SigUtils.t.sol` provides EIP-2612 permit signature construction for testing.
