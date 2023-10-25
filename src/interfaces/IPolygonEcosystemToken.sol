// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/IERC20Permit.sol";
import {IERC20} from "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {IAccessControlEnumerable} from "openzeppelin-contracts/contracts/access/AccessControlEnumerable.sol";

/// @title Polygon ERC20 token
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)
/// @notice This is the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1-to-1 representation between $POL and $MATIC and allows for additional emission based on hub and treasury requirements
/// @custom:security-contact security@polygon.technology
interface IPolygonEcosystemToken is IERC20, IERC20Permit, IAccessControlEnumerable {
    /// @notice emitted when the mint cap is updated
    /// @param oldCap the old mint cap
    /// @param newCap the new mint cap
    event MintCapUpdated(uint256 oldCap, uint256 newCap);

    /// @notice emitted when the permit2 integration is enabled/disabled
    /// @param enabled whether the permit2 integration is enabled or not
    event Permit2AllowanceUpdated(bool enabled);

    /// @notice thrown when a zero address is supplied during deployment
    error InvalidAddress();

    /// @notice thrown when the mint cap is exceeded
    /// @param maxMint the maximum amount of tokens that can be minted
    /// @param mintRequested the amount of tokens that were requested to be minted
    error MaxMintExceeded(uint256 maxMint, uint256 mintRequested);

    /// @notice mint token entrypoint for the emission manager contract
    /// @param to address to mint to
    /// @param amount amount to mint
    /// @dev The function only validates the sender, the emission manager is responsible for correctness
    function mint(address to, uint256 amount) external;

    /// @notice update the limit of tokens that can be minted per second
    /// @param newCap the amount of tokens in 18 decimals as an absolute value
    function updateMintCap(uint256 newCap) external;

    /// @notice manages the default max approval to the permit2 contract
    /// @param enabled If true, the permit2 contract has full approval by default, if false, it has no approval by default
    function updatePermit2Allowance(bool enabled) external;

    /// @return the role that allows minting of tokens
    function EMISSION_ROLE() external view returns (bytes32);

    /// @return the role that allows updating the mint cap
    function CAP_MANAGER_ROLE() external view returns (bytes32);

    /// @return the role that allows revoking the permit2 approval
    function PERMIT2_REVOKER_ROLE() external view returns (bytes32);

    /// @return the address of the permit2 contract
    function PERMIT2() external view returns (address);

    /// @return currentMintPerSecondCap the current amount of tokens that can be minted per second
    /// @dev 13.37 POL tokens per second. will limit emission in ~12 years
    function mintPerSecondCap() external view returns (uint256 currentMintPerSecondCap);

    /// @return lastMintTimestamp the timestamp of the last mint
    function lastMint() external view returns (uint256 lastMintTimestamp);

    /// @return isPermit2Enabled whether the permit2 default approval is currently active
    function permit2Enabled() external view returns (bool isPermit2Enabled);

    /// @notice returns the version of the contract
    /// @return version version string
    /// @dev this is to support our dev pipeline, and is present despite this contract not being behind a proxy
    function version() external pure returns (string memory version);
}
