// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IPolygon} from "./interfaces/IPolygon.sol";

/// @title Polygon ERC20 token
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice This is the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional inflation based
/// on hub and treasury requirements
/// @custom:security-contact security@polygon.technology
contract Polygon is ERC20Permit, IPolygon {
    address public immutable inflationManager;

    constructor(
        address migration_,
        address inflationManager_
    ) ERC20("Polygon", "POL") ERC20Permit("Polygon") {
        if (migration_ == address(0) || inflationManager_ == address(0))
            revert InvalidAddress();

        inflationManager = inflationManager_;
        _mint(migration_, 10_000_000_000e18);
    }

    /// @notice Mint token entrypoint for the inflation manager contract
    /// @dev The function only validates the sender, the inflation manager is responsible for correctness
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != inflationManager) revert OnlyInflationManager();

        _mint(to, amount);
    }
}
