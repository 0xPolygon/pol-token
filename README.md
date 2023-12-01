# Polygon Ecosystem Token (POL)

![Test Status](https://github.com/github/docs/actions/workflows/test.yml/badge.svg)

The Polygon Ecosystem Token is intended as an upgrade to the [MATIC token](https://etherscan.io/address/0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0). It consists of a [token contract](https://github.com/0xPolygon/pol-token/tree/main/src/PolygonEcosystemToken.sol), [migration contract](https://github.com/0xPolygon/pol-token/tree/main/src/PolygonMigration.sol), and an [emission manager contract](https://github.com/0xPolygon/pol-token/tree/main/src/DefaultEmissionManager.sol). Together, this set of contracts is proposed in [PIP-17](https://github.com/maticnetwork/Polygon-Improvement-Proposals/blob/main/PIPs/PIP-17.md) to Polygon Governance as a step forward in functionality for the polygon ecosystem.

## POL Token Contract

POL is broadly based on the MIT-licensed OpenZeppelin ERC-20 implementations which provide support for the default ERC-20 standard, along with some non-standard functions for allowance modifications. The implementation also provides support for [EIP-2612: Signature-Based Permit Approvals](https://eips.ethereum.org/EIPS/eip-2612)-style is supported).

The POL token contract is not upgradable.

[Source Code](https://github.com/0xPolygon/pol-token/tree/main/src/PolygonEcosystemToken.sol)

## Migration Contract

The migration contract allows 1-to-1 migrations between MATIC and POL using the `migrate` and `unmigrate` functions respectively. This migration contract is ownable, and the owner has the ability to disable the `ummigrate` functionality. For both actions, [EIP-2612 Permit](https://eips.ethereum.org/EIPS/eip-2612)-style is supported.

[Source Code](https://github.com/0xPolygon/pol-token/tree/main/src/PolygonMigration.sol)

## Emission Manager Contract

The role of the Emission Manager is to have the exclusive ability to mint new POL tokens. It has the ability to calculate token emissions based upon a yearly rate, and then dispurse them linearly to a configured target `StakeManager`. For safety, there is a cap on the number of tokens mintable per second as defined by [`mintPerSecondCap`](https://github.com/0xPolygon/pol-token/blob/main/src/PolygonEcosystemToken.sol#L16) on the token implementation.

A default implementation is included and this contract will be proxy upgradable by Polygon Governance.

[Source Code](https://github.com/0xPolygon/pol-token/tree/main/src/DefaultEmissionManager.sol)

## Development

### Setup

- [Install foundry](https://book.getfoundry.sh/getting-started/installation)
- Install Dependencies: `forge install`
- Build: `forge build`
- Test: `forge test`

### Deployment

Forge scripts are used to deploy or upgrade contracts and an additional extract.js script can be used to generate a JSON and Markdown file with coalesced deployment information. (see [deployments](./deployments/))

1. Ensure .env file is set, `cp .env.example .env`

2. `source .env`

3. Deploy using foundry

Note: There are multiple versions available. For this example, we use `1.0.0`.

- (mainnet): `forge script script/1.0.0/Deploy.s.sol --broadcast --verify --rpc-url $RPC_URL --etherscan-api-key $ETHERSCAN_API_KEY`
- (testnet, goerli for example): `forge script script/1.0.0/Deploy.s.sol --broadcast --verify --rpc-url $RPC_URL --verifier-url https://api-goerli.etherscan.io/api --chain-id 5`

4. Run `node script/util/extract.js <chainId> [version = 1.0.0] [scriptName = Deploy.s.sol]` to extract deployment information from forge broadcast output (broadcast/latest-run.json).

## Reference Deployments

- Ethereum Mainnet [0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6](https://etherscan.io/address/0x455e53CBB86018Ac2B8092FdCd39d8444aFFC3F6)
- Goerli [0x4f34BF3352A701AEc924CE34d6CfC373eABb186c](https://goerli.etherscan.io/address/0x4f34BF3352A701AEc924CE34d6CfC373eABb186c)

---

Copyright (C) 2023 PT Services DMCC
