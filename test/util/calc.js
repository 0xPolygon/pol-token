const emissionRatePerYear = 1.025;

function main() {
    const [timeElapsedInSeconds] = process.argv.slice(2);
    const [startSupply] = process.argv.slice(3);

    const supplyFactor = Math.pow(emissionRatePerYear, timeElapsedInSeconds / (365 * 24 * 60 * 60));
    const newSupply = BigInt(startSupply * supplyFactor);

    console.log("0x" + newSupply.toString(16).padStart(64, "0")); // abi.encode(toMint)
}

main();
