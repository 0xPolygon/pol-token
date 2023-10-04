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
async function main() {
  const [chainId] = process.argv.slice(2);
  const commitHash = getCommitHash();
  const data = JSON.parse(
    readFileSync(join(__dirname, `../../broadcast/Deploy.s.sol/${chainId}/run-latest.json`), "utf-8")
  );
  const config = JSON.parse(readFileSync(join(__dirname, "../config.json"), "utf-8"));
  const rpcUrl = config.defaultRpc[chainId] || process.env.RPC_URL || "http://127.0.0.1:8545";
  const deployments = data.transactions.filter(({ transactionType }) => transactionType === "CREATE"); // CREATE2?
  const deployedContractsMap = new Map(
    [...deployments].map(({ contractName, contractAddress }) => [contractAddress, contractName])
  );

  // todo(future): add support for other proxy patterns
  const proxies = await Promise.all(
    deployments
      .filter(({ contractName }) => contractName === "TransparentUpgradeableProxy")
      .map(async ({ arguments, contractAddress, transaction: { data } }) => ({
        implementation: arguments[0],
        proxyAdmin: arguments[1],
        address: contractAddress,
        contractName: deployedContractsMap.get(arguments[0]),
        proxy: true,
        ...(await getVersion(contractAddress, rpcUrl)),
        proxyType: "TransparentUpgradeableProxy",
      }))
  );
  const nonProxies = await Promise.all(
    deployments
      .filter(
        ({ contractName }) =>
          contractName !== "TransparentUpgradeableProxy" &&
          !proxies.find((p) => p.contractName === contractName)
      )
      .map(async ({ contractName, contractAddress, transaction: { data } }) => ({
        address: contractAddress,
        contractName,
        proxy: false,
        ...(await getVersion(contractAddress, rpcUrl)),
      }))
  );
  const contracts = [...proxies, ...nonProxies].reduce((obj, { contractName, ...rest }) => {
    obj[contractName] = rest;
    return obj;
  }, {});

  const outPath = join(__dirname, `../../output/${chainId}.json`);
  const out = JSON.parse(
    (existsSync(outPath) && readFileSync(outPath, "utf-8")) || JSON.stringify({ chainId, latest: {}, history: [] })
  );

  // only update if there are changes to specific contracts from history
  if (Object.keys(out.latest).length != 0) {
    if (out.history.find((h) => h.commitHash === commitHash) || out.latest.commitHash === commitHash)
      return console.log("warn: commitHash already deployed"); // if commitHash already exists in history, return
    out.history.unshift(out.latest); // add latest to history
  }
  // overwrite latest with changed contracts
  out.latest = {
    ...out.latest,
    contracts,
    input: config[chainId],
    commitHash,
    timestamp: data.timestamp,
  };

  writeFileSync(outPath, JSON.stringify(out, null, 2));
}

function getCommitHash() {
  return execSync("git rev-parse HEAD").toString().trim(); // note: update if not using git
}

function sha256(data) {
  const { createHash } = require("node:crypto"); // note: update if not using nodejs
  return createHash("sha256").update(data).digest("hex");
}

async function getVersion(contractAddress, rpcUrl) {
  try {
    const res = await (
      await fetch(rpcUrl, {
        method: "POST",
        headers: { "content-type": "application/json" },
        body: JSON.stringify({
          jsonrpc: "2.0",
          id: Date.now(),
          method: "eth_call",
          params: [{ to: contractAddress, data: "0x0d8e6e2c" }, "latest"], // getVersion()(string)
        }),
      })
    ).json();
    if (res.error) throw new Error(res.error.message);
    return { version: hexToAscii(res.result)?.trim() || res.result };
  } catch (e) {
    if (e.message === "execution reverted") return null; // contract does implement getVersion()
    console.log("getVersion error:", rpcUrl, e.message);
    return { version: undefined };
  }
}

const hexToAscii = (str) => hexToUtf8(str).replace(/[\u0000-\u0008,\u000A-\u001F,\u007F-\u00A0]+/g, ""); // remove non-ascii chars
const hexToUtf8 = (str) => new TextDecoder().decode(hexToUint8Array(str)); // note: TextDecoder present in node, update if not using nodejs
function hexToUint8Array(hex) {
  const value = hex.toLowerCase().startsWith("0x") ? hex.slice(2) : hex;
  return new Uint8Array(Math.ceil(value.length / 2)).map((_, i) => parseInt(value.substring(i * 2, i * 2 + 2), 16));
}

main();
