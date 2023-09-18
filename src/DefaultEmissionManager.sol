// SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

import {IPolygonEcosystemToken} from "./interfaces/IPolygonEcosystemToken.sol";
import {IPolygonMigration} from "./interfaces/IPolygonMigration.sol";
import {IDefaultEmissionManager} from "./interfaces/IDefaultEmissionManager.sol";
import {Ownable2StepUpgradeable} from "openzeppelin-contracts-upgradeable/contracts/access/Ownable2StepUpgradeable.sol";
import {Initializable} from "openzeppelin-contracts-upgradeable/contracts/proxy/utils/Initializable.sol";
import {SafeERC20} from "openzeppelin-contracts/contracts/token/ERC20/utils/SafeERC20.sol";
import {PowUtil} from "./lib/PowUtil.sol";

/// @title Default Emission Manager
/// @author Polygon Labs (@DhairyaSethi, @gretzke, @qedk)
/// @notice A default emission manager implementation for the Polygon ERC20 token contract on Ethereum L1
/// @dev The contract allows for a 1% mint *each* per year (compounded every year) to the stakeManager and treasury contracts
/// @custom:security-contact security@polygon.technology
contract DefaultEmissionManager is Initializable, Ownable2StepUpgradeable, IDefaultEmissionManager {
    using SafeERC20 for IPolygonEcosystemToken;

    // log2(2%pa continuously compounded emission per year) in 18 decimals, see _inflatedSupplyAfter
    uint256 public constant INTEREST_PER_YEAR_LOG2 = 0.028569152196770894e18;
    uint256 public constant START_SUPPLY = 10_000_000_000e18;
    address private immutable DEPLOYER;

    IPolygonEcosystemToken public token;
    IPolygonMigration public migration;
    address public stakeManager;
    address public treasury;

    uint256 public startTimestamp;

    constructor() {
        DEPLOYER = msg.sender;
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
        // prevent front-running since we can't initialize on proxy deployment
        if (DEPLOYER != msg.sender) revert();
        if (
            token_ == address(0) ||
            migration_ == address(0) ||
            stakeManager_ == address(0) ||
            treasury_ == address(0) ||
            owner_ == address(0)
        ) revert InvalidAddress();

        token = IPolygonEcosystemToken(token_);
        migration = IPolygonMigration(migration_);
        stakeManager = stakeManager_;
        treasury = treasury_;
        startTimestamp = block.timestamp;

        assert(START_SUPPLY == token.totalSupply());

        token.safeApprove(migration_, type(uint256).max);
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

        uint256 treasuryAmt = amountToMint / 2;
        uint256 stakeManagerAmt = amountToMint - treasuryAmt;

        emit TokenMint(amountToMint, msg.sender);

        token.mint(address(this), amountToMint);
        token.safeTransfer(treasury, treasuryAmt);
        // backconvert POL to MATIC before sending to StakeManager
        migration.unmigrateTo(stakeManager, stakeManagerAmt);
    }

    /// @notice Returns total supply from compounded emission after timeElapsed from startTimestamp (deployment)
    /// @param timeElapsed The time elapsed since startTimestamp
    /// @dev interestRatePerYear = 1.02; 2% per year
    /// approximate the compounded interest rate using x^y = 2^(log2(x)*y)
    /// where x is the interest rate per year and y is the number of seconds elapsed since deployment divided by 365 days in seconds
    /// log2(interestRatePerYear) = 0.028569152196770894 with 18 decimals, as the interest rate does not change, hard code the value
    /// @return supply total supply from compounded emission after timeElapsed
    function inflatedSupplyAfter(uint256 timeElapsed) public pure returns (uint256 supply) {
        uint256 supplyFactor = PowUtil.exp2((INTEREST_PER_YEAR_LOG2 * timeElapsed) / 365 days);
        supply = (supplyFactor * START_SUPPLY) / 1e18;
    }

    /// @notice Returns the implementation version
    /// @return Version string
    function getVersion() external pure returns(string memory) {
        return "1.0.0";
    }

    /**
     * @dev This empty reserved space is put in place to allow future versions to add new
     * variables without shifting down storage in the inheritance chain.
     * See https://docs.openzeppelin.com/contracts/4.x/upgradeable#storage_gaps
     */
    uint256[50] private __gap;
}
