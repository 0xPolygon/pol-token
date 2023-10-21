pragma solidity 0.8.21;

import "../../src/interfaces/IDefaultEmissionManager.sol";
import "../../src/PolygonEcosystemToken.sol";


contract PolygonEcosystemTokenHarness is PolygonEcosystemToken {

    address private _emissionManager;
    constructor(address migration, address emissionManager, address governance, address permit2Revoker) 
        PolygonEcosystemToken(migration, emissionManager, governance, permit2Revoker) {
            _emissionManager = emissionManager;
    }

    function fetchMaxMint() external view returns (uint256) {
        return (block.timestamp - lastMint) * mintPerSecondCap;
    }
}