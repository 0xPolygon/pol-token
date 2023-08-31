//SPDX-License-Identifier: MIT
pragma solidity 0.8.21;

library PowUtil {
    function exp2(uint256 x) internal pure returns (uint256 result) {
        // based on https://github.com/PaulRBerg/prb-math/blob/5959ef59f906d689c2472ed08797872a1cc00644/src/Common.sol#L54
        // usually we would make sure that the number doesn't overflow
        // assert(product <= 192e18 - 1);
        // but it won't overflow in the next 1000 years
        // should it overflow at some point which is more than unlikely, the returned supply factor will be 0
        x = (x << 64) / 1e18;

        unchecked {
            // Start from 0.5 in the 192.64-bit fixed-point format.
            result = 0x800000000000000000000000000000000000000000000000;

            // The following logic multiplies the result by $\sqrt{2^{-i}}$ when the bit at position i is 1. Key points:
            //
            // 1. Intermediate results will not overflow, as the starting point is 2^191 and all magic factors are under 2^65.
            // 2. The rationale for organizing the if statements into groups of 8 is gas savings. If the result of performing
            // a bitwise AND operation between x and any value in the array [0x80; 0x40; 0x20; 0x10; 0x08; 0x04; 0x02; 0x01] is 1,
            // we know that `x & 0xFF` is also 1.
            if (x & 0xFF00000000000000 > 0) {
                if (x & 0x8000000000000000 > 0)
                    result = (result * 0x16A09E667F3BCC909) >> 64;
                if (x & 0x4000000000000000 > 0)
                    result = (result * 0x1306FE0A31B7152DF) >> 64;
                if (x & 0x2000000000000000 > 0)
                    result = (result * 0x1172B83C7D517ADCE) >> 64;
                if (x & 0x1000000000000000 > 0)
                    result = (result * 0x10B5586CF9890F62A) >> 64;
                if (x & 0x800000000000000 > 0)
                    result = (result * 0x1059B0D31585743AE) >> 64;
                if (x & 0x400000000000000 > 0)
                    result = (result * 0x102C9A3E778060EE7) >> 64;
                if (x & 0x200000000000000 > 0)
                    result = (result * 0x10163DA9FB33356D8) >> 64;
                if (x & 0x100000000000000 > 0)
                    result = (result * 0x100B1AFA5ABCBED61) >> 64;
            }

            if (x & 0xFF000000000000 > 0) {
                if (x & 0x80000000000000 > 0)
                    result = (result * 0x10058C86DA1C09EA2) >> 64;
                if (x & 0x40000000000000 > 0)
                    result = (result * 0x1002C605E2E8CEC50) >> 64;
                if (x & 0x20000000000000 > 0)
                    result = (result * 0x100162F3904051FA1) >> 64;
                if (x & 0x10000000000000 > 0)
                    result = (result * 0x1000B175EFFDC76BA) >> 64;
                if (x & 0x8000000000000 > 0)
                    result = (result * 0x100058BA01FB9F96D) >> 64;
                if (x & 0x4000000000000 > 0)
                    result = (result * 0x10002C5CC37DA9492) >> 64;
                if (x & 0x2000000000000 > 0)
                    result = (result * 0x1000162E525EE0547) >> 64;
                if (x & 0x1000000000000 > 0)
                    result = (result * 0x10000B17255775C04) >> 64;
            }

            if (x & 0xFF0000000000 > 0) {
                if (x & 0x800000000000 > 0)
                    result = (result * 0x1000058B91B5BC9AE) >> 64;
                if (x & 0x400000000000 > 0)
                    result = (result * 0x100002C5C89D5EC6D) >> 64;
                if (x & 0x200000000000 > 0)
                    result = (result * 0x10000162E43F4F831) >> 64;
                if (x & 0x100000000000 > 0)
                    result = (result * 0x100000B1721BCFC9A) >> 64;
                if (x & 0x80000000000 > 0)
                    result = (result * 0x10000058B90CF1E6E) >> 64;
                if (x & 0x40000000000 > 0)
                    result = (result * 0x1000002C5C863B73F) >> 64;
                if (x & 0x20000000000 > 0)
                    result = (result * 0x100000162E430E5A2) >> 64;
                if (x & 0x10000000000 > 0)
                    result = (result * 0x1000000B172183551) >> 64;
            }

            if (x & 0xFF00000000 > 0) {
                if (x & 0x8000000000 > 0)
                    result = (result * 0x100000058B90C0B49) >> 64;
                if (x & 0x4000000000 > 0)
                    result = (result * 0x10000002C5C8601CC) >> 64;
                if (x & 0x2000000000 > 0)
                    result = (result * 0x1000000162E42FFF0) >> 64;
                if (x & 0x1000000000 > 0)
                    result = (result * 0x10000000B17217FBB) >> 64;
                if (x & 0x800000000 > 0)
                    result = (result * 0x1000000058B90BFCE) >> 64;
                if (x & 0x400000000 > 0)
                    result = (result * 0x100000002C5C85FE3) >> 64;
                if (x & 0x200000000 > 0)
                    result = (result * 0x10000000162E42FF1) >> 64;
                if (x & 0x100000000 > 0)
                    result = (result * 0x100000000B17217F8) >> 64;
            }

            if (x & 0xFF000000 > 0) {
                if (x & 0x80000000 > 0)
                    result = (result * 0x10000000058B90BFC) >> 64;
                if (x & 0x40000000 > 0)
                    result = (result * 0x1000000002C5C85FE) >> 64;
                if (x & 0x20000000 > 0)
                    result = (result * 0x100000000162E42FF) >> 64;
                if (x & 0x10000000 > 0)
                    result = (result * 0x1000000000B17217F) >> 64;
                if (x & 0x8000000 > 0)
                    result = (result * 0x100000000058B90C0) >> 64;
                if (x & 0x4000000 > 0)
                    result = (result * 0x10000000002C5C860) >> 64;
                if (x & 0x2000000 > 0)
                    result = (result * 0x1000000000162E430) >> 64;
                if (x & 0x1000000 > 0)
                    result = (result * 0x10000000000B17218) >> 64;
            }

            if (x & 0xFF0000 > 0) {
                if (x & 0x800000 > 0)
                    result = (result * 0x1000000000058B90C) >> 64;
                if (x & 0x400000 > 0)
                    result = (result * 0x100000000002C5C86) >> 64;
                if (x & 0x200000 > 0)
                    result = (result * 0x10000000000162E43) >> 64;
                if (x & 0x100000 > 0)
                    result = (result * 0x100000000000B1721) >> 64;
                if (x & 0x80000 > 0)
                    result = (result * 0x10000000000058B91) >> 64;
                if (x & 0x40000 > 0)
                    result = (result * 0x1000000000002C5C8) >> 64;
                if (x & 0x20000 > 0)
                    result = (result * 0x100000000000162E4) >> 64;
                if (x & 0x10000 > 0)
                    result = (result * 0x1000000000000B172) >> 64;
            }

            if (x & 0xFF00 > 0) {
                if (x & 0x8000 > 0)
                    result = (result * 0x100000000000058B9) >> 64;
                if (x & 0x4000 > 0)
                    result = (result * 0x10000000000002C5D) >> 64;
                if (x & 0x2000 > 0)
                    result = (result * 0x1000000000000162E) >> 64;
                if (x & 0x1000 > 0)
                    result = (result * 0x10000000000000B17) >> 64;
                if (x & 0x800 > 0)
                    result = (result * 0x1000000000000058C) >> 64;
                if (x & 0x400 > 0)
                    result = (result * 0x100000000000002C6) >> 64;
                if (x & 0x200 > 0)
                    result = (result * 0x10000000000000163) >> 64;
                if (x & 0x100 > 0)
                    result = (result * 0x100000000000000B1) >> 64;
            }

            if (x & 0xFF > 0) {
                if (x & 0x80 > 0) result = (result * 0x10000000000000059) >> 64;
                if (x & 0x40 > 0) result = (result * 0x1000000000000002C) >> 64;
                if (x & 0x20 > 0) result = (result * 0x10000000000000016) >> 64;
                if (x & 0x10 > 0) result = (result * 0x1000000000000000B) >> 64;
                if (x & 0x8 > 0) result = (result * 0x10000000000000006) >> 64;
                if (x & 0x4 > 0) result = (result * 0x10000000000000003) >> 64;
                if (x & 0x2 > 0) result = (result * 0x10000000000000001) >> 64;
                if (x & 0x1 > 0) result = (result * 0x10000000000000001) >> 64;
            }

            // In the code snippet below, two operations are executed simultaneously:
            //
            // 1. The result is multiplied by $(2^n + 1)$, where $2^n$ represents the integer part, and the additional 1
            // accounts for the initial guess of 0.5. This is achieved by subtracting from 191 instead of 192.
            // 2. The result is then converted to an unsigned 60.18-decimal fixed-point format.
            //
            // The underlying logic is based on the relationship $2^{191-ip} = 2^{ip} / 2^{191}$, where $ip$ denotes the,
            // integer part, $2^n$.
            result *= 1e18;
            result >>= (191 - (x >> 64));
        }
    }
}
