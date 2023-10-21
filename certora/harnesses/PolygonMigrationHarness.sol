pragma solidity 0.8.21;

import "../../src/PolygonMigration.sol";


contract PolygonMigrationHarness is PolygonMigration {
    constructor(address matic_) PolygonMigration(matic_) {}
}