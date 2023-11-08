pragma solidity 0.8.21;

import "../../src/DefaultEmissionManager.sol";


contract DefaultEmissionManagerHarness is DefaultEmissionManager {
    using SafeERC20 for IPolygonEcosystemToken;
    
    constructor(
        address token_,
        address migration_,
        address stakeManager_,
        address treasury_,
        address owner_
    )  DefaultEmissionManager(migration_, stakeManager_, treasury_)
    {
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

    function amountToBeMinted() external view returns (uint256) {
        uint256 timeElapsed = block.timestamp - startTimestamp;
        uint256 supplyFactor = PowUtil.exp2((INTEREST_PER_YEAR_LOG2 * timeElapsed) / 365 days);
        uint256 newSupply = (supplyFactor * START_SUPPLY) / 1e18;

        return newSupply - token.totalSupply();
    }

    function externalExp2(uint256 value) external pure returns (uint256) {
        return PowUtil.exp2(value);
    }
}