pragma solidity 0.8.21;

import "../../src/lib/PowUtil.sol";

contract PowUtilHarness {
    function exp2(uint256 value) external pure returns (uint256) {
        return PowUtil.exp2(value);
    }
}

