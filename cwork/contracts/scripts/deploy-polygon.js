const { ethers } = require("hardhat");
const { saveFrontendFiles } = require("./utils");

async function main() {
  console.log("Deploying to Polygon network...");
  
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);
  console.log("Account balance:", (await deployer.getBalance()).toString());

  // Deploy FreelanceEscrow contract with treasury address
  const treasuryAddress = "0x1338D0Cf46B9D5e58B302a450478D9a5a52b6e23";
  const FreelanceEscrow = await ethers.getContractFactory("FreelanceEscrow");
  const freelanceEscrow = await FreelanceEscrow.deploy(treasuryAddress);
  await freelanceEscrow.deployed();

  console.log("FreelanceEscrow deployed to:", freelanceEscrow.address);

  // Deploy MockERC20 for testing
  const MockERC20 = await ethers.getContractFactory("MockERC20");
  const mockToken = await MockERC20.deploy(
    "CWork Stablecoin",
    "CWS",
    ethers.utils.parseUnits("1000000", 18)
  );
  await mockToken.deployed();

  console.log("MockERC20 deployed to:", mockToken.address);

  // Save contract addresses and ABI for frontend
  await saveFrontendFiles(freelanceEscrow, "FreelanceEscrowPolygon");
  await saveFrontendFiles(mockToken, "MockERC20Polygon");

  console.log("Polygon deployment completed successfully!");
}

if (require.main === module) {
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });
}

module.exports = { main };