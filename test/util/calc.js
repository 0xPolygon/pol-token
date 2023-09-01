const interestRatePerSecond = 1.000000000634195839
const startSupply = 10_000_000_000e18
function main() {
  const [timeElapsedInSeconds] = process.argv.slice(2)

  const supplyFactor = Math.pow(interestRatePerSecond, timeElapsedInSeconds)
  const newSupply = BigInt(startSupply * supplyFactor)

  console.log('0x' + newSupply.toString(16).padStart(64, '0')) // abi.encode(toMint)
}

main();
