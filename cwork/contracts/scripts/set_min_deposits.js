const { ethers } = require("hardhat");

async function main() {
  // Get the deployed FreelanceEscrow contract
  const FreelanceEscrow = await ethers.getContractFactory("FreelanceEscrow");
  const freelanceEscrow = await FreelanceEscrow.attach(process.env.ESCROW_CONTRACT_ADDRESS);
  
  console.log("Setting minimum deposit amounts...");
  
  // Set minimum deposit for ETH (0.05 ETH)
  const minEth = ethers.parseEther("0.05");
  const tx1 = await freelanceEscrow.setMinDeposit(ethers.ZeroAddress, minEth);
  await tx1.wait();
  console.log(`Set ETH minimum deposit to ${ethers.formatEther(minEth)} ETH`);
  
  // Set minimum deposit for USDT (10 USDT with 6 decimals)
  // Note: Replace with actual USDT contract address
  const usdtAddress = process.env.USDT_ADDRESS || "0xYourUSDTContractAddress";
  const minUsdt = ethers.parseUnits("10", 6);
  const tx2 = await freelanceEscrow.setMinDeposit(usdtAddress, minUsdt);
  await tx2.wait();
  console.log(`Set USDT minimum deposit to ${ethers.formatUnits(minUsdt, 6)} USDT`);
  
  // Set minimum deposit for USDC (10 USDC with 6 decimals)
  // Note: Replace with actual USDC contract address
  const usdcAddress = process.env.USDC_ADDRESS || "0xYourUSDCContractAddress";
  const minUsdc = ethers.parseUnits("10", 6);
  const tx3 = await freelanceEscrow.setMinDeposit(usdcAddress, minUsdc);
  await tx3.wait();
  console.log(`Set USDC minimum deposit to ${ethers.formatUnits(minUsdc, 6)} USDC`);
  
  console.log("Minimum deposit configuration completed!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });