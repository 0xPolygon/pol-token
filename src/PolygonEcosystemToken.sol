// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {ERC20, ERC20Permit, IERC20} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {AccessControlEnumerable} from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";
import {IPolygonEcosystemToken} from "./interfaces/IPolygonEcosystemToken.sol";

/// @title Polygon ERC20 token
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)
/// @notice This is the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based on hub and treasury requirements
/// @custom:security-contact security@polygon.technology
contract PolygonEcosystemToken is ERC20Permit, AccessControlEnumerable, IPolygonEcosystemToken {
    bytes32 public constant EMISSION_ROLE = keccak256("EMISSION_ROLE");
    bytes32 public constant CAP_MANAGER_ROLE = keccak256("CAP_MANAGER_ROLE");
    bytes32 public constant PERMIT2_REVOKER_ROLE = keccak256("PERMIT2_REVOKER_ROLE");
    address public constant PERMIT2 = 0x000000000022D473030F116dDEE9F6B43aC78BA3;
    uint256 public mintPerSecondCap = 13.37e18;
    uint256 public lastMint;
    bool public permit2Enabled;

    constructor(
        address migration,
        address emissionManager,
        address protocolCouncil,
        address emergencyCouncil
    ) ERC20("Polygon Ecosystem Token", "POL") ERC20Permit("Polygon Ecosystem Token") {
        if (
            migration == address(0) ||
            emissionManager == address(0) ||
            protocolCouncil == address(0) ||
            emergencyCouncil == address(0)
        ) revert InvalidAddress();
        _grantRole(DEFAULT_ADMIN_ROLE, protocolCouncil);
        _grantRole(EMISSION_ROLE, emissionManager);
        _grantRole(CAP_MANAGER_ROLE, protocolCouncil);
        _grantRole(PERMIT2_REVOKER_ROLE, protocolCouncil);
        _grantRole(PERMIT2_REVOKER_ROLE, emergencyCouncil);
        _mint(migration, 10_000_000_000e18);
        // we can safely set lastMint here since the emission manager is initialised after the token and won't hit the cap.
        lastMint = block.timestamp;
        _updatePermit2Allowance(true);
    }

    /// @inheritdoc IPolygonEcosystemToken
    function mint(address to, uint256 amount) external onlyRole(EMISSION_ROLE) {
        uint256 timeElapsedSinceLastMint = block.timestamp - lastMint;
        uint256 maxMint = timeElapsedSinceLastMint * mintPerSecondCap;
        if (amount > maxMint) revert MaxMintExceeded(maxMint, amount);

        lastMint = block.timestamp;
        _mint(to, amount);
    }

    /// @inheritdoc IPolygonEcosystemToken
    function updateMintCap(uint256 newCap) external onlyRole(CAP_MANAGER_ROLE) {
        emit MintCapUpdated(mintPerSecondCap, newCap);
        mintPerSecondCap = newCap;
    }

    /// @inheritdoc IPolygonEcosystemToken
    function updatePermit2Allowance(bool enabled) external onlyRole(PERMIT2_REVOKER_ROLE) {
        _updatePermit2Allowance(enabled);
    }

    /// @dev The permit2 contract has full approval by default. If the approval is revoked, it can still be manually approved.
    function allowance(address owner, address spender) public view override(ERC20, IERC20) returns (uint256) {
        if (spender == PERMIT2 && permit2Enabled) return type(uint256).max;
        return super.allowance(owner, spender);
    }

    /// @inheritdoc IPolygonEcosystemToken
    function version() external pure returns (string memory) {
        return "1.1.0";
    }

    function _updatePermit2Allowance(bool enabled) private {
        emit Permit2AllowanceUpdated(enabled);
        permit2Enabled = enabled;
    }
}
