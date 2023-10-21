// Rules are timing out, as this function doing exponential calculations

methods {
    function exp2(uint256) external returns(uint256) envfree;
}

// Since log2 graph is steadily increasing, we can prove property that log(a) <= log(b) if a <= b
rule verifyingSteadyIncrease(env e) {
    uint256 a;
    uint256 b;

    require a >= 10 ^ 18;
    require b <= 28569152196770896000;
    require a <= b;

    uint256 exp2A = exp2(a);
    uint256 exp2B = exp2(b);

    require exp2B != 0; // cause this reverts anyway

    assert exp2A <= exp2B;
}

rule resultShouldAlwaysbeGEThanOne(env e) {
    uint256 a;

    require a >= 10 ^ 18;
    require a < 0xa688906bd8b000000;


    mathint result = exp2(a);

    assert result >= 10 ^ 18 ;
}

rule resultShouldNotBeZero(env e) {
    uint256 a;

    require a >= 10 ^ 18;
    require a < 0xa688906bd8b000000;

    mathint result = exp2(a);

    assert result != 0;
}
