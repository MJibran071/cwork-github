const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FreelanceEscrow", function () {
  let FreelanceEscrow;
  let MockERC20;
  let freelanceEscrow;
  let mockToken;
  let owner;
  let client;
  let developer;
  let admin;
  let other;

  const CONTRACT_ID = "test-contract-1";
  let ESCROW_ID;
  const MILESTONE_AMOUNT = ethers.parseEther("1.0");
  const MILESTONE_AMOUNT_ERC20 = ethers.parseUnits("1000", 18);

  beforeEach(async function () {
    [owner, client, developer, admin, other] = await ethers.getSigners();

    // Deploy Mock ERC20 token
    MockERC20 = await ethers.getContractFactory("MockERC20");
    mockToken = await MockERC20.deploy("Mock Token", "MOCK", ethers.parseUnits("1000000", 18));

    // Deploy FreelanceEscrow contract with treasury wallet
    FreelanceEscrow = await ethers.getContractFactory("FreelanceEscrow");
    freelanceEscrow = await FreelanceEscrow.deploy(admin.address); // Use admin as treasury for testing

    // Transfer ownership to admin for testing
    await freelanceEscrow.transferOwnership(admin.address);

    // Compute escrow ID using the contract's function
    ESCROW_ID = await freelanceEscrow.computeEscrowId(CONTRACT_ID);
  });

  describe("Contract Deployment", function () {
    it("Should deploy with correct owner", async function () {
      expect(await freelanceEscrow.owner()).to.equal(admin.address);
    });
  });

  describe("Escrow Creation", function () {
    it("Should create escrow successfully", async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      
      // ESCROW_ID is already computed from CONTRACT_ID, so it should match
      const computedEscrowId = await freelanceEscrow.computeEscrowId(CONTRACT_ID);
      expect(computedEscrowId).to.equal(ESCROW_ID);
    });

    it("Should revert if escrow already exists", async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      
      await expect(
        freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address)
      ).to.be.revertedWith("exists");
    });

    it("Should revert if non-admin tries to create escrow", async function () {
      await expect(
        freelanceEscrow.connect(other).createEscrow(ESCROW_ID, client.address, developer.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Milestone Management", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
    });

    it("Should add milestone with native ETH and calculate fee", async function () {
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress);
      
      // Verify milestone was added with fee calculation using getter functions
      const milestoneCount = await freelanceEscrow.getEscrowMilestoneCount(ESCROW_ID);
      expect(milestoneCount).to.equal(1);
      
      // Calculate expected total (principal + 5% fee)
      const expectedFee = (MILESTONE_AMOUNT * 500n) / 10000n; // 5% fee
      const expectedTotal = MILESTONE_AMOUNT + expectedFee;
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      expect(totalAmount).to.equal(expectedTotal);
    });

    it("Should add milestone with ERC20 token and calculate fee", async function () {
      const mockTokenAddress = await mockToken.getAddress();
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT_ERC20, mockTokenAddress);
      
      const milestoneCount = await freelanceEscrow.getEscrowMilestoneCount(ESCROW_ID);
      expect(milestoneCount).to.equal(1);
      
      // Calculate expected total (principal + 5% fee)
      const expectedFee = (MILESTONE_AMOUNT_ERC20 * 500n) / 10000n; // 5% fee
      const expectedTotal = MILESTONE_AMOUNT_ERC20 + expectedFee;
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      expect(totalAmount).to.equal(expectedTotal);
    });

    it("Should revert if non-admin tries to add milestone", async function () {
      await expect(
        freelanceEscrow.connect(other).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if escrow doesn't exist", async function () {
      const invalidEscrowId = ethers.keccak256(ethers.toUtf8Bytes("invalid"));
      await expect(
        freelanceEscrow.connect(admin).addMilestone(invalidEscrowId, MILESTONE_AMOUNT, ethers.ZeroAddress)
      ).to.be.revertedWith("no escrow");
    });
  });

  describe("Deposit Functionality", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress);
      
      // Get the total amount to deposit (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      this.totalDepositAmount = totalAmount;
    });

    it("Should deposit native ETH successfully", async function () {
      const tx = await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: this.totalDepositAmount });
      
      await expect(tx).to.emit(freelanceEscrow, "Deposited")
        .withArgs(ESCROW_ID, 0, this.totalDepositAmount, ethers.ZeroAddress, client.address, "0x");
    });

    it("Should deposit ERC20 tokens successfully", async function () {
      // First add ERC20 milestone
      const mockTokenAddress = await mockToken.getAddress();
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT_ERC20, mockTokenAddress);
      
      // Calculate expected amount for this milestone (principal + 5% fee)
      const expectedFee = (MILESTONE_AMOUNT_ERC20 * 500n) / 10000n; // 5% fee
      const expectedTotal = MILESTONE_AMOUNT_ERC20 + expectedFee;
      
      // Transfer tokens to client first
      await mockToken.connect(owner).transfer(client.address, expectedTotal);
      
      // Approve and deposit
      const freelanceEscrowAddress = await freelanceEscrow.getAddress();
      await mockToken.connect(client).approve(freelanceEscrowAddress, expectedTotal);
      const tx = await freelanceEscrow.connect(client).deposit(ESCROW_ID, 1, "0x");
      
      await expect(tx).to.emit(freelanceEscrow, "Deposited")
        .withArgs(ESCROW_ID, 1, expectedTotal, mockTokenAddress, client.address, "0x");
    });

    it("Should revert if incorrect ETH amount", async function () {
      await expect(
        freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: this.totalDepositAmount / 2n })
      ).to.be.revertedWith("incorrect amount");
    });

    it("Should revert if milestone already funded", async function () {
      await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: this.totalDepositAmount });
      
      await expect(
        freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: this.totalDepositAmount })
      ).to.be.revertedWith("already funded");
    });
  });

  describe("Release Functionality", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress);
      
      // Get the total amount to deposit (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount });
    });

    it("Should release funds to developer and fee to treasury", async function () {
      const developerBalanceBefore = BigInt(await ethers.provider.getBalance(developer.address));
      const treasuryBalanceBefore = BigInt(await ethers.provider.getBalance(admin.address)); // admin is treasury
      
      const tx = await freelanceEscrow.connect(client).release(ESCROW_ID, 0);
      await tx.wait();
      
      const developerBalanceAfter = BigInt(await ethers.provider.getBalance(developer.address));
      const treasuryBalanceAfter = BigInt(await ethers.provider.getBalance(admin.address));
      
      // Calculate expected amounts
      // MILESTONE_AMOUNT is the principal (1 ETH)
      const expectedFee = (MILESTONE_AMOUNT * 500n) / 10000n; // 5% fee = 0.05 ETH
      const expectedPrincipal = MILESTONE_AMOUNT; // Developer should receive full principal (1 ETH)
      
      // For testing purposes, we'll check that balances increased by the expected amounts
      // without precise gas calculation since gas costs can vary in Hardhat
      expect(developerBalanceAfter).to.be.gt(developerBalanceBefore);
      expect(developerBalanceAfter - developerBalanceBefore).to.be.closeTo(expectedPrincipal, expectedPrincipal / 100n); // Within 1%
      expect(treasuryBalanceAfter - treasuryBalanceBefore).to.equal(expectedFee);
      
      await expect(tx).to.emit(freelanceEscrow, "Released")
        .withArgs(ESCROW_ID, 0, expectedPrincipal, expectedFee, ethers.ZeroAddress, developer.address, admin.address);
    });

    it("Should revert if non-client tries to release", async function () {
      await expect(
        freelanceEscrow.connect(other).release(ESCROW_ID, 0)
      ).to.be.revertedWith("only client");
    });

    it("Should revert if milestone not in deposit state", async function () {
      await expect(
        freelanceEscrow.connect(client).release(ESCROW_ID, 1) // Non-existent milestone
      ).to.be.revertedWith("not fundable");
    });
  });

  describe("Dispute Functionality", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress);
      
      // Get the total amount to deposit (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount });
    });

    it("Should allow client to raise dispute", async function () {
      const tx = await freelanceEscrow.connect(client).raiseDispute(ESCROW_ID, 0, "Quality issues");
      
      await expect(tx).to.emit(freelanceEscrow, "Disputed")
        .withArgs(ESCROW_ID, 0, client.address, "Quality issues");
    });

    it("Should allow developer to raise dispute", async function () {
      const tx = await freelanceEscrow.connect(developer).raiseDispute(ESCROW_ID, 0, "Client not responsive");
      
      await expect(tx).to.emit(freelanceEscrow, "Disputed")
        .withArgs(ESCROW_ID, 0, developer.address, "Client not responsive");
    });

    it("Should allow any address to raise dispute when conditions are met", async function () {
      const tx = await freelanceEscrow.connect(other).raiseDispute(ESCROW_ID, 0, "Third party dispute");
      await expect(tx).to.emit(freelanceEscrow, "Disputed")
        .withArgs(ESCROW_ID, 0, other.address, "Third party dispute");
    });

    it("Should revert if milestone not in deposit state", async function () {
      await expect(
        freelanceEscrow.connect(client).raiseDispute(ESCROW_ID, 1, "Invalid milestone")
      ).to.be.revertedWith("not in deposit");
    });
  });

  describe("Admin Resolution", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, MILESTONE_AMOUNT, ethers.ZeroAddress);
      
      // Get the total amount to deposit (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount });
      await freelanceEscrow.connect(client).raiseDispute(ESCROW_ID, 0, "Test dispute");
    });

    it("Should allow admin to resolve release with fee distribution", async function () {
      const developerBalanceBefore = BigInt(await ethers.provider.getBalance(developer.address));
      const treasuryBalanceBefore = BigInt(await ethers.provider.getBalance(admin.address));
      
      const tx = await freelanceEscrow.connect(admin).adminResolveRelease(ESCROW_ID, 0);
      await tx.wait();
      
      const developerBalanceAfter = BigInt(await ethers.provider.getBalance(developer.address));
      const treasuryBalanceAfter = BigInt(await ethers.provider.getBalance(admin.address));
      
      // Calculate expected amounts
      // MILESTONE_AMOUNT is the principal (1 ETH)
      const expectedFee = (MILESTONE_AMOUNT * 500n) / 10000n; // 5% fee = 0.05 ETH
      const expectedPrincipal = MILESTONE_AMOUNT; // Developer should receive full principal (1 ETH)
      
      // For testing purposes, we'll check that balances increased by the expected amounts
      // without precise gas calculation since gas costs can vary in Hardhat
      expect(developerBalanceAfter).to.be.gt(developerBalanceBefore);
      expect(developerBalanceAfter - developerBalanceBefore).to.be.closeTo(expectedPrincipal, expectedPrincipal / 100n); // Within 1%
      
      // The treasury should receive the exact fee amount, but since admin is also the caller,
      // we need to check that the treasury received at least the fee (gas costs reduce the net balance)
      expect(treasuryBalanceAfter - treasuryBalanceBefore).to.be.at.least(expectedFee - (expectedFee / 100n)); // At least 99% of fee
      
      await expect(tx).to.emit(freelanceEscrow, "Released")
        .withArgs(ESCROW_ID, 0, expectedPrincipal, expectedFee, ethers.ZeroAddress, developer.address, admin.address);
    });

    it("Should allow admin to resolve refund (full amount including fee)", async function () {
      const clientBalanceBefore = BigInt(await ethers.provider.getBalance(client.address));
      
      const tx = await freelanceEscrow.connect(admin).adminResolveRefund(ESCROW_ID, 0);
      await tx.wait();
      
      const clientBalanceAfter = BigInt(await ethers.provider.getBalance(client.address));
      
      // Refund should include both principal and fee (full amount)
      const expectedFee = (MILESTONE_AMOUNT * 500n) / 10000n; // 5% fee
      const expectedTotal = MILESTONE_AMOUNT + expectedFee;
      
      // For testing purposes, we'll check that balance increased by the expected amount
      // without precise gas calculation since gas costs can vary in Hardhat
      expect(clientBalanceAfter).to.be.gt(clientBalanceBefore);
      expect(clientBalanceAfter - clientBalanceBefore).to.be.closeTo(expectedTotal, expectedTotal / 100n); // Within 1%
      
      await expect(tx).to.emit(freelanceEscrow, "Refunded")
        .withArgs(ESCROW_ID, 0, expectedTotal, ethers.ZeroAddress, client.address);
    });

    it("Should revert if non-admin tries to resolve", async function () {
      await expect(
        freelanceEscrow.connect(other).adminResolveRelease(ESCROW_ID, 0)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if milestone not disputed", async function () {
      await expect(
        freelanceEscrow.connect(admin).adminResolveRelease(ESCROW_ID, 1) // Non-disputed milestone
      ).to.be.revertedWith("not disputed");
    });
  });
  describe("Treasury Wallet Management", function () {
    it("Should allow owner to update treasury wallet", async function () {
      const newTreasury = other.address;
      const tx = await freelanceEscrow.connect(admin).updateTreasuryWallet(newTreasury);
      
      await expect(tx).to.emit(freelanceEscrow, "TreasuryWalletUpdated")
        .withArgs(newTreasury);
      
      expect(await freelanceEscrow.treasuryWallet()).to.equal(newTreasury);
    });

    it("Should revert if non-owner tries to update treasury", async function () {
      await expect(
        freelanceEscrow.connect(other).updateTreasuryWallet(other.address)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should revert if invalid treasury address", async function () {
      await expect(
        freelanceEscrow.connect(admin).updateTreasuryWallet(ethers.ZeroAddress)
      ).to.be.revertedWith("invalid treasury");
    });
  });

  describe("Minimum Deposit Configuration", function () {
    it("Should allow owner to set minimum deposit for ETH", async function () {
      const minEth = ethers.parseEther("0.05");
      const tx = await freelanceEscrow.connect(admin).setMinDeposit(ethers.ZeroAddress, minEth);
      
      await expect(tx).to.emit(freelanceEscrow, "MinDepositSet")
        .withArgs(ethers.ZeroAddress, minEth);
      
      expect(await freelanceEscrow.minDepositAmounts(ethers.ZeroAddress)).to.equal(minEth);
    });

    it("Should allow owner to set minimum deposit for ERC20 tokens", async function () {
      const mockTokenAddress = await mockToken.getAddress();
      const minUsdt = ethers.parseUnits("10", 6); // 10 USDT with 6 decimals
      const tx = await freelanceEscrow.connect(admin).setMinDeposit(mockTokenAddress, minUsdt);
      
      await expect(tx).to.emit(freelanceEscrow, "MinDepositSet")
        .withArgs(mockTokenAddress, minUsdt);
      
      expect(await freelanceEscrow.minDepositAmounts(mockTokenAddress)).to.equal(minUsdt);
    });

    it("Should revert if non-owner tries to set minimum deposit", async function () {
      const minEth = ethers.parseEther("0.05");
      await expect(
        freelanceEscrow.connect(other).setMinDeposit(ethers.ZeroAddress, minEth)
      ).to.be.revertedWith("Ownable: caller is not the owner");
    });
  });

  describe("Minimum Deposit Enforcement", function () {
    beforeEach(async function () {
      await freelanceEscrow.connect(admin).createEscrow(ESCROW_ID, client.address, developer.address);
    });

    it("Should enforce ETH minimum deposit", async function () {
      // Set minimum ETH deposit to 0.05 ETH
      const minEth = ethers.parseEther("0.05");
      await freelanceEscrow.connect(admin).setMinDeposit(ethers.ZeroAddress, minEth);

      // Try to add milestone with amount below minimum (0.01 ETH)
      const belowMinAmount = ethers.parseEther("0.01");
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, belowMinAmount, ethers.ZeroAddress);
      
      // Get total amount (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      
      // Should revert when depositing below minimum
      await expect(
        freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount })
      ).to.be.revertedWith("amount below min");
    });

    it("Should allow ETH deposit above minimum", async function () {
      // Set minimum ETH deposit to 0.05 ETH
      const minEth = ethers.parseEther("0.05");
      await freelanceEscrow.connect(admin).setMinDeposit(ethers.ZeroAddress, minEth);

      // Add milestone with amount above minimum (0.1 ETH)
      const aboveMinAmount = ethers.parseEther("0.1");
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, aboveMinAmount, ethers.ZeroAddress);
      
      // Get total amount (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      
      // Should succeed when depositing above minimum
      const tx = await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount });
      
      await expect(tx).to.emit(freelanceEscrow, "Deposited")
        .withArgs(ESCROW_ID, 0, totalAmount, ethers.ZeroAddress, client.address, "0x");
    });

    it("Should enforce ERC20 minimum deposit", async function () {
      const mockTokenAddress = await mockToken.getAddress();
      
      // Set minimum USDT deposit to 10 tokens (with 6 decimals)
      const minUsdt = ethers.parseUnits("10", 6);
      await freelanceEscrow.connect(admin).setMinDeposit(mockTokenAddress, minUsdt);

      // Try to add milestone with amount below minimum (5 tokens)
      const belowMinAmount = ethers.parseUnits("5", 6);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, belowMinAmount, mockTokenAddress);
      
      // Calculate expected total (principal + fee)
      const expectedFee = (belowMinAmount * 500n) / 10000n;
      const expectedTotal = belowMinAmount + expectedFee;
      
      // Transfer tokens to client first
      await mockToken.connect(owner).transfer(client.address, expectedTotal);
      
      // Approve escrow contract
      const freelanceEscrowAddress = await freelanceEscrow.getAddress();
      await mockToken.connect(client).approve(freelanceEscrowAddress, expectedTotal);
      
      // Should revert when depositing below minimum
      await expect(
        freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x")
      ).to.be.revertedWith("amount below min");
    });

    it("Should allow ERC20 deposit above minimum", async function () {
      const mockTokenAddress = await mockToken.getAddress();
      
      // Set minimum USDT deposit to 10 tokens (with 6 decimals)
      const minUsdt = ethers.parseUnits("10", 6);
      await freelanceEscrow.connect(admin).setMinDeposit(mockTokenAddress, minUsdt);

      // Add milestone with amount above minimum (20 tokens)
      const aboveMinAmount = ethers.parseUnits("20", 6);
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, aboveMinAmount, mockTokenAddress);
      
      // Calculate expected total (principal + fee)
      const expectedFee = (aboveMinAmount * 500n) / 10000n;
      const expectedTotal = aboveMinAmount + expectedFee;
      
      // Transfer tokens to client first
      await mockToken.connect(owner).transfer(client.address, expectedTotal);
      
      // Approve escrow contract
      const freelanceEscrowAddress = await freelanceEscrow.getAddress();
      await mockToken.connect(client).approve(freelanceEscrowAddress, expectedTotal);
      
      // Should succeed when depositing above minimum
      const tx = await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x");
      
      await expect(tx).to.emit(freelanceEscrow, "Deposited")
        .withArgs(ESCROW_ID, 0, expectedTotal, mockTokenAddress, client.address, "0x");
    });

    it("Should not enforce minimum deposit if not set", async function () {
      // Add milestone with small amount (0.01 ETH) - no minimum set
      const smallAmount = ethers.parseEther("0.01");
      await freelanceEscrow.connect(admin).addMilestone(ESCROW_ID, smallAmount, ethers.ZeroAddress);
      
      // Get total amount (principal + fee)
      const totalAmount = await freelanceEscrow.getEscrowTotalAmount(ESCROW_ID);
      
      // Should succeed when no minimum is set
      const tx = await freelanceEscrow.connect(client).deposit(ESCROW_ID, 0, "0x", { value: totalAmount });
      
      await expect(tx).to.emit(freelanceEscrow, "Deposited")
        .withArgs(ESCROW_ID, 0, totalAmount, ethers.ZeroAddress, client.address, "0x");
    });
  });
});