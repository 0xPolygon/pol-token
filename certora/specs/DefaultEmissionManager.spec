import "helpers/helpers.spec";

using PolygonEcosystemToken as _PolygonEcosystemToken;
using DummyERC20Impl as _Matic;
using PowUtilHarness as _PowUtil;


methods {
    function _.exp2(uint256 value) external => fake_exp2(value) expect (uint256);
    function _.exp2(uint256 value) internal => fake_exp2(value) expect (uint256);
    
    function startTimestamp() external returns (uint256) envfree;
    function treasury() external returns (address) envfree;
    function stakeManager() external returns (address) envfree;
    function migration() external returns (address) envfree;
    function amountToBeMinted() external returns (uint256);

    function _PolygonEcosystemToken.balanceOf(address) external returns(uint256) envfree;
    function _Matic.balanceOf(address) external returns(uint256) envfree;
    function _PolygonEcosystemToken.totalSupply() external returns(uint256) envfree;
    function _Matic.totalSupply() external returns(uint256) envfree;

    function _.unmigrateTo(address, uint256) external => DISPATCHER(true);
    function _.startTimestamp() external     => DISPATCHER(true);
}

// Assuming that exp2 gonna grow as value of value is grow
function fake_exp2(uint256 value) returns uint256 {
    return require_uint256(value + 1);
}

ghost mathint sumOfBalancesPolygon {
    init_state axiom sumOfBalancesPolygon == 0;
}

hook Sload uint256 balance _PolygonEcosystemToken._balances[KEY address addr] STORAGE {
    require sumOfBalancesPolygon >= to_mathint(balance);
}

hook Sstore _PolygonEcosystemToken._balances[KEY address addr] uint256 newValue (uint256 oldValue) STORAGE {
    sumOfBalancesPolygon = sumOfBalancesPolygon - oldValue + newValue;
}

invariant totalSupplyIsSumOfBalancesPolygon()
    to_mathint(_PolygonEcosystemToken.totalSupply()) == sumOfBalancesPolygon;


ghost mathint sumOfBalancesMatic {
    init_state axiom sumOfBalancesMatic == 0;
}

hook Sload uint256 balance _Matic._balances[KEY address addr] STORAGE {
    require sumOfBalancesMatic >= to_mathint(balance);
}

hook Sstore _Matic._balances[KEY address addr] uint256 newValue (uint256 oldValue) STORAGE {
    sumOfBalancesMatic = sumOfBalancesMatic - oldValue + newValue;
}


invariant totalSupplyIsSumOfBalancesMatic()
    to_mathint(_Matic.totalSupply()) == sumOfBalancesMatic;



rule correctAmountIsBeingTransferredOnMint (
    env e
) {
    requireInvariant totalSupplyIsSumOfBalancesPolygon();
    requireInvariant totalSupplyIsSumOfBalancesMatic();

    address treasury = treasury();
    address migration = migration();
    address stakeManager = stakeManager();
    address other;

    require treasury != migration && treasury != stakeManager;
    require migration != stakeManager && migration != other;
    require other != treasury && other != stakeManager;

    mathint treasuryBalanceBefore = _PolygonEcosystemToken.balanceOf(treasury);
    mathint migrationBalanceBefore = _PolygonEcosystemToken.balanceOf(migration);
    mathint migrationBalanceBeforeMatic = _Matic.balanceOf(migration);
    mathint stakeManagerBalanceBefore = _PolygonEcosystemToken.balanceOf(stakeManager);
    mathint stakeManagerBalanceBeforeMatic = _Matic.balanceOf(stakeManager);

    mathint otherBalanceBefore = _PolygonEcosystemToken.balanceOf(other);
    mathint otherBalanceBeforeMatic = _Matic.balanceOf(other);

    mathint amountShouldbeMinted = amountToBeMinted(e);

    mint(e);

    mathint treasuryBalanceAfter = _PolygonEcosystemToken.balanceOf(treasury);
    mathint migrationBalanceAfter = _PolygonEcosystemToken.balanceOf(migration);
    mathint migrationBalanceAfterMatic = _Matic.balanceOf(migration);
    mathint stakeManagerBalanceAfter = _PolygonEcosystemToken.balanceOf(stakeManager);
    mathint stakeManagerBalanceAfterMatic = _Matic.balanceOf(stakeManager);

    mathint otherBalanceAfter = _PolygonEcosystemToken.balanceOf(other);
    mathint otherBalanceAfterMatic = _Matic.balanceOf(other);

    mathint amountMintedToTreasury = treasuryBalanceAfter - treasuryBalanceBefore;
    mathint amountMintedToMigration = stakeManagerBalanceAfterMatic - stakeManagerBalanceBeforeMatic;

    assert amountShouldbeMinted/3 == amountMintedToTreasury, "1.1";
    assert ((amountShouldbeMinted - amountShouldbeMinted / 3) == amountMintedToMigration) ||
        (amountShouldbeMinted - amountShouldbeMinted / 3 + 1)== amountMintedToMigration, "1.2";

    assert treasuryBalanceBefore + amountMintedToTreasury == treasuryBalanceAfter, "1.3";
    assert migrationBalanceBefore + amountMintedToMigration == migrationBalanceAfter, "1.4";
    assert migrationBalanceBeforeMatic -  amountMintedToMigration == migrationBalanceAfterMatic, "1.5";
    assert stakeManagerBalanceBefore == stakeManagerBalanceAfter, "1.6";
    assert stakeManagerBalanceBeforeMatic + amountMintedToMigration == stakeManagerBalanceAfterMatic, "1.7";
    assert stakeManagerBalanceBeforeMatic + amountMintedToMigration == stakeManagerBalanceAfterMatic, "1.8";

    assert otherBalanceBefore == otherBalanceAfter, "1.9";
    assert otherBalanceBeforeMatic == otherBalanceAfterMatic, "1.10";
}

rule mintShoulsIncreaseContinueslyOverTime(
    env e0,
    env e1

) {
    requireInvariant totalSupplyIsSumOfBalancesPolygon();
    requireInvariant totalSupplyIsSumOfBalancesMatic();


    address treasury = treasury();
    address migration = migration();
    address stakeManager = stakeManager();
    address other;

    require treasury != migration && treasury != stakeManager;
    require migration != stakeManager && migration != other;
    require other != treasury && other != stakeManager;
    require e0.block.timestamp < require_uint256(e1.block.timestamp);

    mathint treasuryBalanceBefore = _PolygonEcosystemToken.balanceOf(treasury);
    mathint migrationBalanceBefore = _PolygonEcosystemToken.balanceOf(migration);

    storage initialStorage = lastStorage;
    mint(e0);


    mathint treasuryBalanceAfterFirstMint = _PolygonEcosystemToken.balanceOf(treasury);
    mathint migrationBalanceAfterFirstMint = _PolygonEcosystemToken.balanceOf(migration);
    mint(e1) at initialStorage;

    mathint treasuryBalanceAfterSecondMint = _PolygonEcosystemToken.balanceOf(treasury);
    mathint migrationBalanceAfterSecondMint = _PolygonEcosystemToken.balanceOf(migration);

    mathint amountMintedDuringFirstMint = (treasuryBalanceAfterFirstMint - treasuryBalanceBefore) + (migrationBalanceAfterFirstMint - migrationBalanceBefore);
    mathint amountMintedDuringSecondMint = (treasuryBalanceAfterSecondMint - treasuryBalanceBefore) + (migrationBalanceAfterSecondMint - migrationBalanceBefore);

   assert amountMintedDuringFirstMint < amountMintedDuringSecondMint;
}


rule sanity_satisfy(method f) {
    env e;
    calldataarg args;
    f(e, args);
    satisfy true;
}