const { readFileSync, existsSync, writeFileSync, mkdirSync } = require("fs");
const { execSync } = require("child_process");
const { join } = require("path");

/**
 * @description Extracts contract deployment data from run-latest.json (foundry broadcast output) and writes to output/{chainId}.json
 * @usage node script/utils/extract.js {chainId}
 * @dev
 *  currently only supports TransparentUpgradeableProxy pattern
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
  const timestamp = data.timestamp;

  // todo(future): add support for other proxy patterns
  const proxies = await Promise.all(
    deployments
      .filter(({ contractName }) => contractName === "TransparentUpgradeableProxy")
      .map(async ({ arguments, contractAddress, hash }) => ({
        implementation: arguments[0],
        proxyAdmin: arguments[1],
        address: contractAddress,
        contractName: deployedContractsMap.get(arguments[0]),
        proxy: true,
        ...(await getVersion(contractAddress, rpcUrl)),
        proxyType: "TransparentUpgradeableProxy",
        timestamp,
        deploymentTxn: hash,
        commitHash,
      }))
  );
  const nonProxies = await Promise.all(
    deployments
      .filter(
        ({ contractName }) =>
          contractName !== "TransparentUpgradeableProxy" && !proxies.find((p) => p.contractName === contractName)
      )
      .map(async ({ contractName, contractAddress, hash }) => ({
        address: contractAddress,
        contractName,
        proxy: false,
        ...(await getVersion(contractAddress, rpcUrl)),
        timestamp,
        deploymentTxn: hash,
        commitHash,
      }))
  );
  const contracts = [...proxies, ...nonProxies].reduce((obj, { contractName, ...rest }) => {
    obj[contractName] = rest;
    return obj;
  }, {});

  const outPath = join(__dirname, `../../output/${chainId}.json`);
  if (!existsSync(join(__dirname, "../../output/"))) mkdirSync(join(__dirname, "../../output/"));
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
    contracts: {
      ...out.latest?.contracts,
      ...contracts,
    },
    input: config[chainId],
    commitHash,
    timestamp,
  };

  writeFileSync(outPath, JSON.stringify(out, null, 2));
  generateMarkdown(out);
}

function getCommitHash() {
  return execSync("git rev-parse HEAD").toString().trim(); // note: update if not using git
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
    if (e.message === "execution reverted") return { version: undefined }; // contract does not implement getVersion()
    if (e.message.includes("fetch is not defined")) {
      console.warn("use node 18+");
    }
    throw e;
  }
}

function generateMarkdown(input) {
  let out = `# Polygon Ecosystem Token\n\n`;
  // read name from foundry.toml

  out += `\n### Table of Contents\n- [Summary](#summary)\n- [Contracts](#contracts)\n\t- `;
  out += Object.keys(input.latest.contracts)
    .map(
      (c) =>
        `[${c.replace(/([A-Z])/g, " $1").trim()}](#${c
          .replace(/([A-Z])/g, "-$1")
          .trim()
          .slice(1)
          .toLowerCase()})`
    )
    .join("\n\t- ");
  out += `\n ## Summary
  <table>
  <tr>
      <th>Contract</th>
      <th>Address</th>
  </tr>`;
  out += Object.entries(input.latest.contracts)
    .map(
      ([contractName, { address }]) =>
        `<tr>
      <td>${contractName}</td>
      <td><a href="${getEtherscanLink(input.chainId, address)}" target="_blank">${address}</a></td>
      </tr>`
    )
    .join("\n");
  out += `</table>\n`;

  out += `\n## Contracts\n\n`;

  out += Object.entries(input.latest.contracts)
    .map(
      ([
        contractName,
        { address, deploymentTxn, version, commitHash, timestamp, proxyType, implementation, proxyAdmin },
      ]) => `### ${contractName.replace(/([A-Z])/g, " $1").trim()}

Address: ${getEtherscanLinkMd(input.chainId, address)}

Deployment Txn: ${getEtherscanLinkMd(input.chainId, deploymentTxn, "tx")}

${
  typeof version === "undefined"
    ? ""
    : `Version: [${version}](https://github.com/0xPolygon/pol-token/releases/tag/${version})`
}

Commit Hash: [${commitHash.slice(0, 7)}](https://github.com/0xPolygon/pol-token/commit/${commitHash})

${prettifyTimestamp(timestamp)}
${generateProxyInformationIfProxy({
  address,
  contractName,
  proxyType,
  implementation,
  proxyAdmin,
  history: input.history,
  chainId: input.chainId,
})}`
    )
    .join("\n\n");

  out += `
### Deployment History

${generateDeploymentHistory(input.history, input.latest, input.chainId)}`;

  writeFileSync(join(__dirname, `../../output/${input.chainId}.md`), out, "utf-8");
}

function getEtherscanLink(chainId, address, slug = "address") {
  chainId = parseInt(chainId);
  switch (chainId) {
    case 1:
      return `https://etherscan.io/${slug}/${address}`;
    case 5:
      return `https://goerli.etherscan.io/${slug}/${address}`;
    default:
      return ``;
    // return `https://blockscan.com/${slug}/${address}`;
  }
}
function getEtherscanLinkMd(chainId, address, slug = "address") {
  const etherscanLink = getEtherscanLink(chainId, address, slug);
  return etherscanLink.length ? `[${address}](${etherscanLink})` : address;
}

function generateProxyInformationIfProxy({
  address,
  contractName,
  proxyType,
  implementation,
  proxyAdmin,
  history,
  chainId,
}) {
  let out = ``;
  if (typeof proxyType === "undefined") return out;
  out += `\n\n_Proxy Information_\n\n`;
  out += `\n\nProxy Type: ${proxyType}\n\n`;
  out += `\n\nImplementation: ${getEtherscanLinkMd(chainId, implementation)}\n\n`;
  out += `\n\nProxy Admin: ${getEtherscanLinkMd(chainId, proxyAdmin)}\n\n`;

  const historyOfProxy = history.filter((h) => h?.contracts[contractName].address === address);
  if (historyOfProxy.length === 0) return out;
  out += `\n\nHistory\n\n`;
  out += `
<details>
<summary>Implementation History</sumamry>
<table>
    <tr>
        <th>Version</th>
        <th>Address</th>
        <th>Commit Hash</th>
    </tr>${historyOfProxy
      .map(
        ({
          contracts: {
            [contractName]: { implementation, commitHash, version },
          },
        }) => `
    <tr>
        <td><a href="https://github.com/0xPolygon/pol-token/releases/tag/${version}" target="_blank">${version}</a></td>
        <td><a href="${getEtherscanLink(
          chainId,
          implementation
        )}" target="_blank">${implementation}</a>${implementation}</td>
        <td><a href="https://github.com/0xPolygon/pol-token/commit/${commitHash}" target="_blank">${commitHash.slice(
          0,
          7
        )}</a></td>
    </tr>`
      )
      .join("\n")}
</table>
</details>
  `;
  return out;
}

function generateDeploymentHistory(history, latest, chainId) {
  const allVersions = [...history, latest].reduce((obj, { contracts, input }) => {
    Object.entries(contracts).forEach(([contractName, contract]) => {
      if (typeof contract.version === "undefined") return;
      if (!obj[contract.version]) obj[contract.version] = [];
      obj[contract.version].push({ contract, contractName, input });
    });
    return obj;
  }, {});
  let out = ``;
  out += Object.entries(allVersions)
    .map(
      ([version, contractInfos]) => `
### [${version}](https://github.com/0xPolygon/pol-token/releases/tag/${version})

${prettifyTimestamp(contractInfos[0].contract.timestamp)}

Deployed contracts:

- ${contractInfos
        .map(
          ({ contract, contractName }) =>
            `[${contractName.replace(/([A-Z])/g, " $1").trim()}](${getEtherscanLink(chainId, contract.address)})${
              contract.proxyType ? ` ([implementation](${getEtherscanLink(chainId, contract.implementation)}))` : ``
            }`
        )
        .join("\n- ")}

<details>
<summary>Inputs</summary>
<table>
    <tr>
        <th>Parameter</th>
        <th>Value</th>
    </tr>
    ${Object.entries(contractInfos[0].input)
      .map(
        ([key, value]) => `
<tr>
    <td>${key}</td>
    <td>${value}</td>
</tr>`
      )
      .join("\n")}
</table>
</details>
    `
    )
    .join("\n\n");

  return out;
}

function prettifyTimestamp(timestamp) {
  return new Date(timestamp * 1000).toLocaleString("en-GB", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
    hour: "2-digit",
    minute: "2-digit",
  });
}

const hexToAscii = (str) => hexToUtf8(str).replace(/[\u0000-\u0008,\u000A-\u001F,\u007F-\u00A0]+/g, ""); // remove non-ascii chars
const hexToUtf8 = (str) => new TextDecoder().decode(hexToUint8Array(str)); // note: TextDecoder present in node, update if not using nodejs
function hexToUint8Array(hex) {
  const value = hex.toLowerCase().startsWith("0x") ? hex.slice(2) : hex;
  return new Uint8Array(Math.ceil(value.length / 2)).map((_, i) => parseInt(value.substring(i * 2, i * 2 + 2), 16));
}

// main();
module.exports = { generateMarkdown };
