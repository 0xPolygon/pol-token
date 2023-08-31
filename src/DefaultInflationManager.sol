// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IMinter} from "./interfaces/IMinter.sol";
import {IPolygon} from "./interfaces/IPolygon.sol";
import {IPolygonMigration} from "./interfaces/IPolygonMigration.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PowUtil} from "./lib/PowUtil.sol";

/// @title Default Inflation Manager
/// @author QEDK <qedk.en@gmail.com> (https://polygon.technology)
/// @notice A default inflation manager implementation for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1% mint *each* per year (compounded every second) to the stakeManager and treasury contracts
/// @custom:security-contact security@polygon.technology
contract DefaultInflationManager is
    Initializable,
    Ownable2StepUpgradeable,
    IMinter
{
    using SafeERC20 for IPolygon;

    error InvalidAddress();
    error NotEnoughMint();

    // log2(2%pa continuously compounded inflation per second) in 18 decimals(Wad), see _inflatedSupplyAfter
    uint256 public constant INTEREST_PER_SECOND_LOG2 = 0.000000000914951192e18;
    uint256 public constant START_SUPPLY = 10_000_000_000e18;

    IPolygon public token;
    IPolygonMigration public migration;
    address public stakeManager;
    address public treasury;

    uint256 public startTimestamp;

    constructor() {
        // so that the implementation contract cannot be initialized
        _disableInitializers();
    }

    function initialize(
        address token_,
        address migration_,
        address stakeManager_,
        address treasury_,
        address owner_
    ) external initializer {
        if (
            token_ == address(0) ||
            migration_ == address(0) ||
            stakeManager_ == address(0) ||
            treasury_ == address(0) ||
            owner_ == address(0)
        ) revert InvalidAddress();

        token = IPolygon(token_);
        migration = IPolygonMigration(migration_);
        stakeManager = stakeManager_;
        treasury = treasury_;
        startTimestamp = block.timestamp;

        assert(START_SUPPLY == token.totalSupply());

        token.safeApprove(migration_, type(uint256).max);

        _transferOwnership(owner_);
    }

    /// @notice Allows anyone to mint tokens to the stakeManager and treasury contracts based on current inflation rates
    /// @dev Minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any
    /// previous mints) and the newSupply (calculated based on the time elapsed since deployment)
    function mint() external {
        uint256 currentSupply = token.totalSupply(); // totalSupply after the last mint
        uint256 newSupply = _inflatedSupplyAfter(
            block.timestamp - startTimestamp // time elapsed since deployment
        );
        uint256 amountToMint;
        unchecked {
            // currentSupply is always less than newSupply because POL token is strictly inflationary,
            // _burn method is not exposed
            amountToMint = newSupply - currentSupply;
        }
        if (amountToMint == 0) revert NotEnoughMint();

        uint256 treasuryAmt = amountToMint / 2;
        uint256 stakeManagerAmt = amountToMint - treasuryAmt;

        token.mint(treasury, treasuryAmt);
        // backconvert POL to MATIC before sending to StakeManager
        token.mint(address(this), stakeManagerAmt);
        migration.unmigrateTo(stakeManagerAmt, stakeManager);
    }

    /// @notice Returns total supply from compounded inflation after timeElapsed from startTimestamp (deployment)
    /// @param timeElapsed The time elapsed since startTimestamp
    /// @dev interestRatePerSecond = 1.000000000634195839; 2% per year in seconds with 18 decimals
    /// approximate the compounded interest rate per second using x^y = 2^(log2(x)*y)
    /// where x is the interest rate per second and y is the number of seconds elapsed since deployment
    /// log2(interestRatePerSecond) = 0.000000000914951192 with 18 decimals, as the interest rate does not change, hard code the value
    /// @return supply total supply from compounded inflation after timeElapsed
    function _inflatedSupplyAfter(
        uint256 timeElapsed
    ) private pure returns (uint256 supply) {
        uint256 supplyFactor = PowUtil.exp2(
            INTEREST_PER_SECOND_LOG2 * timeElapsed
        );
        supply = (supplyFactor * START_SUPPLY) / 1e18;
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[49] private __gap;
}
