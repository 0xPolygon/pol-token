// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

struct Beneficiary {
    uint256 mintedAmountPerYear;
    address beneficiary;
    uint96 lastMint;
    uint256 mintModificationLock;
}

library MintingManager {
    error MintModificationLocked(uint256 unlockTimestamp);
    error OnlyDecrease();

    function create(
        address beneficiary,
        uint256 mintedAmountPerYear
    ) internal view returns (Beneficiary memory) {
        return
            Beneficiary({
                mintedAmountPerYear: mintedAmountPerYear,
                beneficiary: beneficiary,
                lastMint: uint96(block.timestamp),
                mintModificationLock: block.timestamp + 10 * 365 days
            });
    }

    function pendingMintedTokens(
        Beneficiary storage self
    ) internal view returns (uint256 amount) {
        uint256 timeDiff = block.timestamp - self.lastMint;
        amount = (timeDiff * self.mintedAmountPerYear) / (365 days);
    }

    function claimMintedTokens(
        Beneficiary storage self
    ) internal returns (uint256 amount) {
        amount = pendingMintedTokens(self);
        self.lastMint = uint96(block.timestamp);
    }

    function decreaseInflation(
        Beneficiary storage self,
        uint256 newMintedAmountPerYear
    ) internal {
        if (block.timestamp < self.mintModificationLock)
            revert MintModificationLocked(self.mintModificationLock);

        if (newMintedAmountPerYear >= self.mintedAmountPerYear)
            revert OnlyDecrease();

        assert(self.lastMint == block.timestamp);
        self.mintedAmountPerYear = newMintedAmountPerYear;
    }

    function addr(Beneficiary storage self) internal view returns (address) {
        return self.beneficiary;
    }
}
