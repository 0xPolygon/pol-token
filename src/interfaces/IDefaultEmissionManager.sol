// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IPolygonEcosystemToken} from "./IPolygonEcosystemToken.sol";

/// @title Default Emission Manager
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)
/// @notice A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 3% mint per year (compounded). 2% staking layer and 1% treasury
/// @custom:security-contact security@polygon.technology
interface IDefaultEmissionManager {
    /// @notice emitted when new tokens are minted
    /// @param amount the amount of tokens minted
    /// @param caller the caller of the mint function
    event TokenMint(uint256 amount, address caller);

    /// @notice thrown when a zero address is supplied during deployment
    error InvalidAddress();

    /// @notice allows anyone to mint tokens to the stakeManager and treasury contracts based on current emission rates
    /// @dev minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any previous mints) and the newSupply (calculated based on the time elapsed since deployment)
    function mint() external;

    /// @return log2(3%pa continuously compounded emission per year) in 18 decimals, see _inflatedSupplyAfter
    function INTEREST_PER_YEAR_LOG2() external view returns (uint256);

    /// @return the start supply of the POL token in 18 decimals
    function START_SUPPLY() external view returns (uint256);

    /// @return polygonEcosystemToken address of the POL token
    function token() external view returns (IPolygonEcosystemToken polygonEcosystemToken);

    /// @return timestamp timestamp of initialisation of the contract, when emission starts
    function startTimestamp() external view returns (uint256 timestamp);

    /// @notice returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)
    /// @param timeElapsedInSeconds the time elapsed since startTimestamp
    /// @return inflatedSupply supply total supply from compounded emission after timeElapsed
    /// @dev interestRatePerYear = 1.03; 3% per year
    /// approximate the compounded interest rate using x^y = 2^(log2(x)*y)
    /// where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
    /// log2(interestRatePerYear) = 0.04264433740849372 with 18 decimals, as the interest rate does not change, hard code the value
    function inflatedSupplyAfter(uint256 timeElapsedInSeconds) external pure returns (uint256 inflatedSupply);

    /// @notice returns the version of the contract
    /// @return version version string
    function getVersion() external pure returns (string memory version);
}
