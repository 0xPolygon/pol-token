# Polygon Ecosystem Token (POL)
![Test Status](https://github.com/github/docs/actions/workflows/test.yml/badge.svg)

The Polygon Ecosystem Token is intended as an upgrade to the existing [MATIC token implementation](https://etherscan.io/address/0x7d1afa7b718fb893db30a3abc0cfc608aacfebb0). It consists of a [token contract](), [migration contract](), and an [emission manager contract](). Together, this set of contracts is proposed in [PIP-18]() to Polygon Governance as a step forward in functionality for the polygon ecosystem.

## POL Token Contract

POL is broadly based on the MIT-licensed OpenZeppelin ERC20 implementations which provide support for the default ERC20 standard, along with some non-standard functions for allowance modifications. The implementation also provides support for EIP-2612: Signature-Based Permit Approvals.

The POL token contract is not upgradable.

[Source Code](https://github.com/0xPolygon/indicia/tree/main/src/PolygonToken.sol)

## Migration Contract

The migration contract allows 1-to-1 swaps between MATIC and POL using the `migrate` and `unmigrate` functions respectively. This migration contract is ownable, and the owner has the ability to disable the `ummigrate` functionality. For both actions, [EIP-2612 Permit]()-style is supported.

[Source Code](https://github.com/0xPolygon/indicia/tree/main/src/PolygonMigratioon.sol)

## Emission Manager Contract
The role of the Emission Manager is to have the exclusive ability to mint new POL tokens. It has the ability to calculate token emissions based upon a yearly rate, and then dispurse them linearly to a configured target `StakeManager`. A default implementation is included and this contract will be proxy upgradable by Polygon Governance.

[Source Code](https://github.com/0xPolygon/indicia/tree/main/src/DefaultInflationManager.sol)

----
Copyright (C) 2023 PT Services DMCC
