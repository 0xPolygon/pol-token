import "helpers/helpers.spec";

using PolygonEcosystemToken as _PolygonEcosystemToken;
using DummyERC20Impl as _Matic;


methods {
    // PolygonMigration functions
    function migrate(uint256) external;
    function unmigrate(uint256) external;
    function unmigrateTo(uint256) external;
    function unmigrateWithPermit(uint256) external;
    function unmigrateWithPermit(uint256,uint256,uint8,bytes32,bytes32) external;
    function updateUnmigrationLock(bool) external;

    function matic() external returns (address) envfree;
    function polygon() external returns (address) envfree;
    function unmigrationLocked() external returns (bool) envfree;
    function owner() external returns (address) envfree;


    // Polygon Harness
    function _PolygonEcosystemToken.allowance(address, address) external returns (uint256) envfree;
    function _PolygonEcosystemToken.balanceOf(address) external returns (uint256) envfree;
    function _PolygonEcosystemToken.totalSupply() external returns (uint256) envfree;
    function _PolygonEcosystemToken.nonces(address) external returns (uint256) envfree;
    function _PolygonEcosystemToken.permit2Enabled() external returns (bool) envfree;
    function _PolygonEcosystemToken.PERMIT2() external returns (address) envfree;

    // Matic Harness
    function _Matic.allowance(address, address) external returns (uint256) envfree;
    function _Matic.balanceOf(address) external returns (uint256) envfree;
    function _Matic.totalSupply() external returns (uint256) envfree;
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

ghost mathint sumOfBalancesMatic {
    init_state axiom sumOfBalancesMatic == 0;
}

hook Sload uint256 balance _Matic._balances[KEY address addr] STORAGE {
    require sumOfBalancesMatic >= to_mathint(balance);
}

hook Sstore _Matic._balances[KEY address addr] uint256 newValue (uint256 oldValue) STORAGE {
    sumOfBalancesMatic = sumOfBalancesMatic - oldValue + newValue;
}

invariant totalSupplyIsSumOfBalances()
    to_mathint(_PolygonEcosystemToken.totalSupply()) == sumOfBalancesPolygon && to_mathint(_Matic.totalSupply()) == sumOfBalancesMatic
    filtered {
        f -> f.selector != sig:setPolygonToken(address).selector 
        // Filtering setPolygonToken function, because it causes vacuous error in cetrora
    }




rule sanity_satisfy(method f) filtered {
    f -> f.selector != sig:setPolygonToken(address).selector
} {
    env e;
    calldataarg args;
    f(e, args);
    satisfy true;
}

rule setUpdateUnmigrationLock(env e) {
    require nonpayable(e);
    bool unmigrationLock;

    updateUnmigrationLock@withrevert(e, unmigrationLock);
    bool didRevert = lastReverted;

    if (didRevert) {
        assert e.msg.sender != owner();
    } else {
        assert unmigrationLocked() == unmigrationLock;
    }
}

rule verifyUnmigrate(env e) {
    uint256 amount;

    requireInvariant totalSupplyIsSumOfBalances();
    require nonpayable(e);
    require nonzerosender(e);
    require e.msg.sender != currentContract;
    require (_PolygonEcosystemToken.allowance(e.msg.sender, currentContract)) >= amount;


    uint256 polygonBalanceBeforeCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceBeforeCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceBeforeContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceBeforeContract = _Matic.balanceOf(currentContract);

    unmigrate@withrevert(e, amount);
    bool didRevert = lastReverted;

    uint256 polygonBalanceAfterCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceAfterCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceAfterContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceAfterContract = _Matic.balanceOf(currentContract);

    if(didRevert) {
        assert polygonBalanceBeforeCaller < amount || maticBalanceBeforeContract < amount || unmigrationLocked() == true;
        assert polygonBalanceBeforeCaller == polygonBalanceAfterCaller && maticBalanceBeforeCaller == maticBalanceAfterCaller;
        assert polygonBalanceBeforeContract == polygonBalanceAfterContract && maticBalanceBeforeContract == maticBalanceAfterContract;
    } else {
        assert assert_uint256(polygonBalanceBeforeCaller - amount) == polygonBalanceAfterCaller;
        assert assert_uint256(maticBalanceBeforeCaller + amount) == maticBalanceAfterCaller;
        assert assert_uint256(polygonBalanceBeforeContract + amount) == polygonBalanceAfterContract;
        assert assert_uint256(maticBalanceBeforeContract - amount) == maticBalanceAfterContract;
    }
}

rule verifyUnmigrateTo(env e) {
    address to;
    uint256 amount;

    requireInvariant totalSupplyIsSumOfBalances();
    require nonpayable(e);
    require nonzerosender(e);
    require nonzeroaddress(to);
    require e.msg.sender != currentContract && to != currentContract && e.msg.sender != to;
    require (_PolygonEcosystemToken.allowance(e.msg.sender, currentContract)) >= amount;


    uint256 polygonBalanceBeforeCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceBeforeCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceBeforeReceiver = _PolygonEcosystemToken.balanceOf(to);
    uint256 maticBalanceBeforeReceiver = _Matic.balanceOf(to);
    uint256 polygonBalanceBeforeContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceBeforeContract = _Matic.balanceOf(currentContract);

    unmigrateTo@withrevert(e, to, amount);
    bool didRevert = lastReverted;

    uint256 polygonBalanceAfterCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceAfterCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceAfterReceiver = _PolygonEcosystemToken.balanceOf(to);
    uint256 maticBalanceAfterReceiver = _Matic.balanceOf(to);
    uint256 polygonBalanceAfterContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceAfterContract = _Matic.balanceOf(currentContract);

    if(didRevert) {
        assert polygonBalanceBeforeCaller < amount || maticBalanceBeforeContract < amount || unmigrationLocked() == true;
        assert polygonBalanceBeforeCaller == polygonBalanceAfterCaller && maticBalanceBeforeCaller == maticBalanceAfterCaller;
        assert polygonBalanceBeforeReceiver == polygonBalanceAfterReceiver && maticBalanceBeforeReceiver == maticBalanceAfterReceiver;
        assert polygonBalanceBeforeContract == polygonBalanceAfterContract && maticBalanceBeforeContract == maticBalanceAfterContract;
    } else {
        assert assert_uint256(polygonBalanceBeforeCaller - amount) == polygonBalanceAfterCaller;
        assert assert_uint256(polygonBalanceBeforeReceiver) == polygonBalanceAfterReceiver;
        assert assert_uint256(maticBalanceBeforeReceiver + amount) == maticBalanceAfterReceiver;
        assert assert_uint256(maticBalanceBeforeCaller) == maticBalanceAfterCaller;
        assert assert_uint256(polygonBalanceBeforeContract + amount) == polygonBalanceAfterContract;
        assert assert_uint256(maticBalanceBeforeContract - amount) == maticBalanceAfterContract;
    }
}

rule unmigrateWithPermit(env e) {
    require nonpayable(e);
    requireInvariant totalSupplyIsSumOfBalances();

    address holder = e.msg.sender;
    address spender = currentContract;
    uint256 amount;
    uint256 deadline;
    uint8 v;
    bytes32 r;
    bytes32 s;

    address account1;
    address account2;
    address account3;

    // cache state
    uint256 nonceBefore          = _PolygonEcosystemToken.nonces(holder);
    uint256 otherNonceBefore     = _PolygonEcosystemToken.nonces(account1);
    uint256 otherAllowanceBefore = _PolygonEcosystemToken.allowance(account2, account3);

    // sanity: nonce overflow, which possible in theory, is assumed to be impossible in practice
    require nonceBefore      < max_uint256;
    require otherNonceBefore < max_uint256;

    uint256 polygonBalanceBeforeCaller = _PolygonEcosystemToken.balanceOf(holder);
    uint256 maticBalanceBeforeCaller = _Matic.balanceOf(holder);
    uint256 polygonBalanceBeforeContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceBeforeContract = _Matic.balanceOf(currentContract);


    // run transaction
    unmigrateWithPermit@withrevert(e, amount, deadline, v, r, s);
    bool didRevert = lastReverted;

    uint256 polygonBalanceAfterCaller = _PolygonEcosystemToken.balanceOf(holder);
    uint256 maticBalanceAfterCaller = _Matic.balanceOf(holder);
    uint256 polygonBalanceAfterContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceAfterContract = _Matic.balanceOf(currentContract);

    uint256 callerAllowanceAfter = _PolygonEcosystemToken.allowance(holder, spender);

    // check outcome
    if (didRevert) {
        assert polygonBalanceBeforeCaller == polygonBalanceAfterCaller && maticBalanceBeforeCaller == maticBalanceAfterCaller;
        assert polygonBalanceBeforeContract == polygonBalanceAfterContract && maticBalanceBeforeContract == maticBalanceAfterContract;

        // Without formally checking the signature, we can't verify exactly the revert causes
        assert polygonBalanceBeforeCaller < amount || maticBalanceBeforeContract < amount || unmigrationLocked() == true || deadline < e.block.timestamp || true;
    } else {
        // allowance and nonce are updated
        assert amount == max_uint256 => (max_uint256) == callerAllowanceAfter;

        assert (amount < max_uint256 && (!_PolygonEcosystemToken.permit2Enabled() || spender != _PolygonEcosystemToken.PERMIT2())) 
            => assert_uint256(0) == callerAllowanceAfter;

        assert to_mathint(_PolygonEcosystemToken.nonces(holder)) == nonceBefore + 1;
        
        assert require_uint256(polygonBalanceBeforeCaller - amount) == polygonBalanceAfterCaller && 
            require_uint256(maticBalanceBeforeCaller + amount) == maticBalanceAfterCaller;

        assert require_uint256(polygonBalanceBeforeContract + amount) == polygonBalanceAfterContract && 
            require_uint256(maticBalanceBeforeContract - amount) == maticBalanceAfterContract;

        // deadline was respected
        assert deadline >= e.block.timestamp;

        // no other allowance or nonce is modified
        assert _PolygonEcosystemToken.nonces(account1)              != otherNonceBefore     => account1 == holder;
        assert _PolygonEcosystemToken.allowance(account2, account3) != otherAllowanceBefore => (account2 == holder && account3 == spender);
    }
}

rule verifyMigrate(env e) {
    uint256 amount;
    address other;

    requireInvariant totalSupplyIsSumOfBalances();
    require nonpayable(e);
    require nonzerosender(e);
    require e.msg.sender != currentContract && e.msg.sender != other;
    require other != currentContract;
    require (_Matic.allowance(e.msg.sender, currentContract)) >= amount;


    uint256 polygonBalanceBeforeCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceBeforeCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceBeforeContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceBeforeContract = _Matic.balanceOf(currentContract);
    uint256 polygonBalanceBeforeOther = _PolygonEcosystemToken.balanceOf(other);
    uint256 maticBalanceBeforeOther = _Matic.balanceOf(other);
    

    migrate@withrevert(e, amount);
    bool didRevert = lastReverted;

    uint256 polygonBalanceAfterCaller = _PolygonEcosystemToken.balanceOf(e.msg.sender);
    uint256 maticBalanceAfterCaller = _Matic.balanceOf(e.msg.sender);
    uint256 polygonBalanceAfterContract = _PolygonEcosystemToken.balanceOf(currentContract);
    uint256 maticBalanceAfterContract = _Matic.balanceOf(currentContract);
    uint256 polygonBalanceAfterOther = _PolygonEcosystemToken.balanceOf(other);
    uint256 maticBalanceAfterOther = _Matic.balanceOf(other);

    if(didRevert) {
        assert maticBalanceBeforeCaller < amount || polygonBalanceBeforeContract < amount;
        assert polygonBalanceBeforeCaller == polygonBalanceAfterCaller && maticBalanceBeforeCaller == maticBalanceAfterCaller;
        assert polygonBalanceBeforeContract == polygonBalanceAfterContract && maticBalanceBeforeContract == maticBalanceAfterContract;
        assert polygonBalanceBeforeOther == polygonBalanceAfterOther && polygonBalanceAfterOther == polygonBalanceAfterOther;
    } else {
        assert assert_uint256(polygonBalanceBeforeCaller + amount) == polygonBalanceAfterCaller;
        assert assert_uint256(maticBalanceBeforeCaller - amount) == maticBalanceAfterCaller;
        assert assert_uint256(polygonBalanceBeforeContract - amount) == polygonBalanceAfterContract;
        assert assert_uint256(maticBalanceBeforeContract + amount) == maticBalanceAfterContract;
        assert polygonBalanceBeforeOther == polygonBalanceAfterOther && polygonBalanceAfterOther == polygonBalanceAfterOther;
    }
}

rule shouldRevertIfUnmigrateIsLocked(env e) {

    uint256 amount;

    requireInvariant totalSupplyIsSumOfBalances();
    require nonpayable(e);
    require nonzerosender(e);
    require e.msg.sender != currentContract;
    require (_PolygonEcosystemToken.allowance(e.msg.sender, currentContract)) >= amount;

    require (_PolygonEcosystemToken.balanceOf(e.msg.sender) >= amount);
    require (_Matic.balanceOf(currentContract) >= amount);
        
    unmigrate@withrevert(e, amount);

    bool didUnmigrateRevert = lastReverted;

    assert didUnmigrateRevert => unmigrationLocked() == true;

}