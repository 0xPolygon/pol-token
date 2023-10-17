// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IPolygonEcosystemToken} from "./interfaces/IPolygonEcosystemToken.sol";
import {IPolygonMigration} from "./interfaces/IPolygonMigration.sol";
import {IDefaultEmissionManager} from "./interfaces/IDefaultEmissionManager.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PowUtil} from "./lib/PowUtil.sol";

/// @title Default Emission Manager
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk, @simonDos)
/// @notice A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 3% mint per year (compounded). 2% stakeManager(Hub) and 1% treasury
/// @custom:security-contact security@polygon.technology
contract DefaultEmissionManager is Ownable2StepUpgradeable, IDefaultEmissionManager {
    using SafeERC20 for IPolygonEcosystemToken;

    // log2(3%pa continuously compounded emission per year) in 18 decimals, see _inflatedSupplyAfter
    uint256 public constant INTEREST_PER_YEAR_LOG2 = 0.04264433740849372e18;
    uint256 public constant START_SUPPLY = 10_000_000_000e18;
    address private immutable DEPLOYER;

    IPolygonMigration public immutable migration;
    address public immutable stakeManager;
    address public immutable treasury;

    IPolygonEcosystemToken public token;
    uint256 public startTimestamp;

    constructor(address migration_, address stakeManager_, address treasury_) {
        if (migration_ == address(0) || stakeManager_ == address(0) || treasury_ == address(0)) revert InvalidAddress();
        DEPLOYER = msg.sender;
        migration = IPolygonMigration(migration_);
        stakeManager = stakeManager_;
        treasury = treasury_;

        // so that the implementation contract cannot be initialized
        _disableInitializers();
    }

    function initialize(address token_, address owner_) external initializer {
        // prevent front-running since we can't initialize on proxy deployment
        if (DEPLOYER != msg.sender) revert();
        if (token_ == address(0) || owner_ == address(0)) revert InvalidAddress();

        token = IPolygonEcosystemToken(token_);
        startTimestamp = block.timestamp;

        assert(START_SUPPLY == token.totalSupply());

        token.safeApprove(address(migration), type(uint256).max);
        // initial ownership setup bypassing 2 step ownership transfer process
        _transferOwnership(owner_);
    }

    /// @notice Allows anyone to mint tokens to the stakeManager and treasury contracts based on current emission rates
    /// @dev Minting is done based on totalSupply diffs between the currentTotalSupply (maintained on POL, which includes any
    /// previous mints) and the newSupply (calculated based on the time elapsed since deployment)
    function mint() external {
        uint256 currentSupply = token.totalSupply(); // totalSupply after the last mint
        uint256 newSupply = inflatedSupplyAfter(
            block.timestamp - startTimestamp // time elapsed since deployment
        );
        uint256 amountToMint = newSupply - currentSupply;
        if (amountToMint == 0) return; // no minting required

        uint256 treasuryAmt = amountToMint / 3;
        uint256 stakeManagerAmt = amountToMint - treasuryAmt;

        emit TokenMint(amountToMint, msg.sender);

        IPolygonEcosystemToken _token = token;
        _token.mint(address(this), amountToMint);
        _token.safeTransfer(treasury, treasuryAmt);
        // backconvert POL to MATIC before sending to StakeManager
        migration.unmigrateTo(stakeManager, stakeManagerAmt);
    }

    /// @notice Returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)
    /// @param timeElapsed The time elapsed since startTimestamp
    /// @dev interestRatePerYear = 1.03; 3% per year
    /// approximate the compounded interest rate using x^y = 2^(log2(x)*y)
    /// where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
    /// log2(interestRatePerYear) = 0.04264433740849372 with 18 decimals, as the interest rate does not change, hard code the value
    /// @return supply total supply from compounded emission after timeElapsed
    function inflatedSupplyAfter(uint256 timeElapsed) public pure returns (uint256 supply) {
        uint256 supplyFactor = PowUtil.exp2((INTEREST_PER_YEAR_LOG2 * timeElapsed) / 365 days);
        supply = (supplyFactor * START_SUPPLY) / 1e18;
    }

    /// @notice Returns the implementation version
    /// @return Version string
    function getVersion() external pure returns (string memory) {
        return "1.1.0";
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[48] private __gap;
}
