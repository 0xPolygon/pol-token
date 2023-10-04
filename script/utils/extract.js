const { readFileSync, existsSync, writeFileSync } = require("fs");
const { execSync } = require("child_process");
const { join } = require("path");

/**
 * @description Extracts contract deployment data from run-latest.json (foundry broadcast output) and writes to output/{chainId}.json
 * @usage node script/utils/extract.js {chainId}
 * @dev
 *  currently only supports TransparentUpgradeableProxy pattern
 *  uses sha256 hash of init code to determine if contract has changed,
 *  uses `node:crypto` module, update if not using nodejs
 */
function main() {
  const [chainId] = process.argv.slice(2);
  const commitHash = getCommitHash();
  const data = JSON.parse(
    readFileSync(join(__dirname, `../../broadcast/Deploy.s.sol/${chainId}/run-latest.json`), "utf-8")
  );
  const deployments = data.transactions.filter(({ transactionType }) => transactionType === "CREATE"); // CREATE2?
  const deployedContractsMap = new Map(
    [...deployments].map(({ contractName, contractAddress }) => [contractAddress, contractName])
  );

  // todo: add support for other proxy patterns
  const proxies = deployments
    .filter(({ contractName }) => contractName === "TransparentUpgradeableProxy")
    .map(({ arguments, contractAddress, transaction: { data } }) => ({
      implementation: arguments[0],
      proxyAdmin: arguments[1],
      address: contractAddress,
      contractName: deployedContractsMap.get(arguments[0]),
      proxy: true,
      version: "",
      initCodeSha256Hash: sha256(data),
      proxyType: "TransparentUpgradeableProxy",
    }));
  const nonProxies = deployments
    .filter(
      ({ contractName }) =>
        contractName !== "TransparentUpgradeableProxy" && !proxies.find((p) => p.contractName === contractName)
    )
    .map(({ contractName, contractAddress, transaction: { data } }) => ({
      address: contractAddress,
      contractName,
      proxy: false,
      version: "",
      initCodeSha256Hash: sha256(data),
    }));
  const contracts = [...proxies, ...nonProxies].reduce((obj, { contractName, ...rest }) => {
    obj[contractName] = rest;
    return obj;
  }, {});

  const outPath = join(__dirname, `../../output/${chainId}.json`);
  const out = existsSync(outPath) ? JSON.parse(readFileSync(outPath, "utf-8")) : { chainId, latest: {}, history: [] };

  // only update if there are changes to specific contracts from history
  if (Object.keys(out.latest).length != 0) {
    if (
      out.history.find((h) => h.commitHash === commitHash) ||
      out.latest.commitHash === commitHash
    ) return console.log('warn: commitHash already deployed'); // if commitHash already exists in history, return
    out.history.unshift(out.latest); // add latest to history
  }
  // overwrite latest with changed contracts
  out.latest = {
    ...out.latest,
    contracts,
    input: JSON.parse(readFileSync(join(__dirname, "../config.json"), "utf-8"))[chainId],
    commitHash,
    timestamp: Date.now(),
  };

  console.log({ out });
  writeFileSync(outPath, JSON.stringify(out, null, 2));
}

function getCommitHash() {
  return execSync("git rev-parse HEAD").toString().trim(); // node: update if not using git
}

function sha256(data) {
  const { createHash } = require("node:crypto"); // note: update if not using nodejs
  return createHash("sha256").update(data).digest("hex");
}

function getVersion(contractAddress, rpcUrl) {
  return "";
}

main();
