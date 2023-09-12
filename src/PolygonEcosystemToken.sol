// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {IPolygonEcosystemToken} from "./interfaces/IPolygonEcosystemToken.sol";
import {IDefaultEmissionManager} from "./interfaces/IDefaultEmissionManager.sol";

/// @title Polygon ERC20 token
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice This is the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based
/// on hub and treasury requirements
/// @custom:security-contact security@polygon.technology
contract PolygonEcosystemToken is ERC20Permit, IPolygonEcosystemToken {
    uint256 public constant MINT_PER_SECOND_CAP = 0.0000000420e18; // 0.0000042% of POL Supply per second, in 18 decimals
    address public immutable emissionManager;
    uint256 public lastMint;

    constructor(
        address migration_,
        address emissionManager_
    ) ERC20("Polygon Ecosystem Token", "POL") ERC20Permit("Polygon") {
        if (migration_ == address(0) || emissionManager_ == address(0)) revert InvalidAddress();

        emissionManager = emissionManager_;
        _mint(migration_, 10_000_000_000e18);
    }

    /// @notice Mint token entrypoint for the emission manager contract
    /// @dev The function only validates the sender, the emission manager is responsible for correctness
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external {
        if (msg.sender != emissionManager) revert OnlyEmissionManager();
        uint256 lastMintCache = lastMint;
        if (lastMintCache == 0) lastMintCache = IDefaultEmissionManager(emissionManager).startTimestamp();

        uint256 timeElapsedSinceLastMint = block.timestamp - lastMintCache;
        uint256 maxMint = (timeElapsedSinceLastMint * MINT_PER_SECOND_CAP * totalSupply()) / 1e18;
        if (amount > maxMint) revert MaxMintExceeded(maxMint, amount);

        lastMint = block.timestamp;
        _mint(to, amount);
    }
}
