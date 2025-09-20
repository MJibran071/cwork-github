const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("MockERC20", function () {
  let MockERC20;
  let mockToken;
  let owner;

  beforeEach(async function () {
    [owner] = await ethers.getSigners();
    MockERC20 = await ethers.getContractFactory("MockERC20");
    mockToken = await MockERC20.deploy("Mock Token", "MOCK", ethers.parseUnits("1000000", 18));
  });

  it("Should deploy with correct address", async function () {
    const address = await mockToken.getAddress();
    expect(address).to.be.a('string');
    expect(address).to.match(/^0x[a-fA-F0-9]{40}$/);
  });

  it("Should have correct name and symbol", async function () {
    expect(await mockToken.name()).to.equal("Mock Token");
    expect(await mockToken.symbol()).to.equal("MOCK");
  });

  it("Should have initial supply", async function () {
    const balance = await mockToken.balanceOf(owner.address);
    expect(balance).to.equal(ethers.parseUnits("1000000", 18));
  });
});