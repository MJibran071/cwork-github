const fs = require("fs");
const path = require("path");

const FRONTEND_DIR = path.join(__dirname, "..", "frontend");

function ensureDirectoryExists(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

async function saveFrontendFiles(contract, contractName) {
  ensureDirectoryExists(FRONTEND_DIR);
  
  const contractsDir = path.join(FRONTEND_DIR, "contracts");
  ensureDirectoryExists(contractsDir);
  
  const abiDir = path.join(FRONTEND_DIR, "abi");
  ensureDirectoryExists(abiDir);
  
  // Save contract address
  const addressFilePath = path.join(contractsDir, `${contractName}-address.json`);
  fs.writeFileSync(
    addressFilePath,
    JSON.stringify({ [contractName]: contract.address }, null, 2)
  );
  
  // Save contract ABI
  const abiFilePath = path.join(abiDir, `${contractName}.json`);
  fs.writeFileSync(
    abiFilePath,
    JSON.stringify(contract.interface.format(ethers.utils.FormatTypes.json), null, 2)
  );
  
  console.log(`Saved ${contractName} address to: ${addressFilePath}`);
  console.log(`Saved ${contractName} ABI to: ${abiFilePath}`);
}

module.exports = { saveFrontendFiles };