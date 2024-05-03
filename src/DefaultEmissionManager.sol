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
/// @dev The contract allows for a 2.5% mint per year (compounded). 1.5% staking layer and 1% treasury
/// @custom:security-contact security@polygon.technology
contract DefaultEmissionManager is Ownable2StepUpgradeable, IDefaultEmissionManager {
    using SafeERC20 for IPolygonEcosystemToken;

    uint256 public constant INTEREST_PER_YEAR_LOG2 = 0.03562390973072122e18; // log2(1.025)
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

    /// @inheritdoc IDefaultEmissionManager
    function mint() external {
        uint256 currentSupply = token.totalSupply(); // totalSupply after the last mint
        uint256 newSupply = inflatedSupplyAfter(
            block.timestamp - startTimestamp // time elapsed since deployment
        );
        uint256 amountToMint = newSupply - currentSupply;
        if (amountToMint == 0) return; // no minting required

        uint256 treasuryAmt = amountToMint * 2 / 5;
        uint256 stakeManagerAmt = amountToMint - treasuryAmt;

        emit TokenMint(amountToMint, msg.sender);

        IPolygonEcosystemToken _token = token;
        _token.mint(address(this), amountToMint);
        _token.safeTransfer(treasury, treasuryAmt);
        // backconvert POL to MATIC before sending to StakeManager
        migration.unmigrateTo(stakeManager, stakeManagerAmt);
    }

    /// @inheritdoc IDefaultEmissionManager
    function inflatedSupplyAfter(uint256 timeElapsed) public pure returns (uint256 supply) {
        uint256 supplyFactor = PowUtil.exp2((INTEREST_PER_YEAR_LOG2 * timeElapsed) / 365 days);
        supply = (supplyFactor * START_SUPPLY) / 1e18;
    }

    /// @inheritdoc IDefaultEmissionManager
    function version() external pure returns (string memory) {
        return "1.2.0";
    }

    uint256[48] private __gap;
}
