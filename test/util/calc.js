const interestRatePerYear = 1.02;
const startSupply = 10_000_000_000e18;
function main() {
  const [timeElapsedInSeconds] = process.argv.slice(2);

  const supplyFactor = Math.pow(interestRatePerYear, timeElapsedInSeconds / (365 * 24 * 60 * 60));
  const newSupply = BigInt(startSupply * supplyFactor);

  console.log("0x" + newSupply.toString(16).padStart(64, "0")); // abi.encode(toMint)
}

main();
