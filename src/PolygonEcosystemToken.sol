// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20, ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControlEnumerable} from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {IPolygonEcosystemToken} from "./interfaces/IPolygonEcosystemToken.sol";

/// @title Polygon ERC20 token
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice This is the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based on hub and treasury requirements
/// @custom:security-contact security@polygon.technology
contract PolygonEcosystemToken is ERC20Permit, AccessControlEnumerable, IPolygonEcosystemToken {
    bytes32 public constant EMISSION_ROLE = keccak256("EMISSION_ROLE");
    bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE");
    uint256 internal constant MAX_MINT_PER_SECOND = 10e18;
    uint256 public mintPerSecondCap = 10e18; // 10 POL tokens per second
    uint256 public lastMint;

    constructor(
        address migration,
        address emissionManager,
        address governance
    ) ERC20("Polygon Ecosystem Token", "POL") ERC20Permit("Polygon Ecosystem Token") {
        if (migration == address(0) || emissionManager == address(0) || governance == address(0))
            revert InvalidAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, governance);
        _grantRole(EMISSION_ROLE, emissionManager);
        _grantRole(CAP_MANAGER_ROLE, governance);
        _mint(migration, 10_000_000_000e18);
        // we can safely set lastMint here since the emission manager is initialised after the token and won't hit the cap.
        lastMint = block.timestamp;
    }

    /// @notice Mint token entrypoint for the emission manager contract
    /// @dev The function only validates the sender, the emission manager is responsible for correctness
    /// @param to Address to mint to
    /// @param amount Amount to mint
    function mint(address to, uint256 amount) external onlyRole(EMISSION_ROLE) {
        uint256 timeElapsedSinceLastMint = block.timestamp - lastMint;
        uint256 maxMint = timeElapsedSinceLastMint * mintPerSecondCap;
        if (amount > maxMint) revert MaxMintExceeded(maxMint, amount);

        lastMint = block.timestamp;
        _mint(to, amount);
    }

    /// @notice Update the limit of tokens that can be minted per second
    /// @param newCap the amount of tokens in 18 decimals as an absolute value
    function updateMintCap(uint256 newCap) external onlyRole(CAP_MANAGER_ROLE) {
        if (newCap > MAX_MINT_PER_SECOND) revert InvalidMintCapUpdate();
        emit MintCapUpdated(mintPerSecondCap, newCap);
        mintPerSecondCap = newCap;
    }
}
