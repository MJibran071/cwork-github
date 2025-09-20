// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FreelanceEscrow is Ownable, ReentrancyGuard {
    enum EscrowStatus { None, Deposited, Released, Disputed, Refunded }

    // Platform fee configuration
    uint256 public constant FEE_PERCENTAGE = 500; // 5.00% in basis points (500/10000 = 5%)
    address public treasuryWallet;

    // Minimum deposit amounts per token
    mapping(address => uint256) public minDepositAmounts;

    struct Milestone {
        uint256 amount;
        address token; // zero address = native ETH
        EscrowStatus status;
        uint256 serviceFee; // Amount of fee for this milestone
    }

    struct ContractEscrow {
        address client;
        address developer;
        uint256 totalAmount;
        bool exists;
        mapping(uint256 => Milestone) milestones; // milestoneIndex => Milestone
        uint256 milestoneCount;
        bool disputed;
    }

    mapping(bytes32 => ContractEscrow) private escrows; // escrowId -> ContractEscrow

    event EscrowCreated(bytes32 indexed escrowId, address client, address developer);
    event Deposited(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 amount, address token, address depositor, bytes txRef);
    event Released(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 principalAmount, uint256 feeAmount, address token, address toFreelancer, address toTreasury);
    event Disputed(bytes32 indexed escrowId, uint256 milestoneIndex, address raisedBy, string reason);
    event Refunded(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 amount, address token, address to);
    event TreasuryWalletUpdated(address newTreasury);
    event MinDepositSet(address indexed token, uint256 minAmount);

    // Helper to compute escrowId externally from a string contract ID
    function computeEscrowId(string memory contractId) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(contractId));
    }

    constructor(address _treasuryWallet) {
        treasuryWallet = _treasuryWallet;
        emit TreasuryWalletUpdated(_treasuryWallet);
    }

    function updateTreasuryWallet(address newTreasury) external onlyOwner {
        require(newTreasury != address(0), "invalid treasury");
        treasuryWallet = newTreasury;
        emit TreasuryWalletUpdated(newTreasury);
    }

    function setMinDeposit(address token, uint256 minAmount) external onlyOwner {
        minDepositAmounts[token] = minAmount;
        emit MinDepositSet(token, minAmount);
    }

    function createEscrow(bytes32 escrowId, address client, address developer) external onlyOwner {
        require(!escrows[escrowId].exists, "exists");
        ContractEscrow storage ce = escrows[escrowId];
        ce.client = client;
        ce.developer = developer;
        ce.exists = true;
        ce.totalAmount = 0;
        ce.milestoneCount = 0;
        emit EscrowCreated(escrowId, client, developer);
    }

    function addMilestone(bytes32 escrowId, uint256 principalAmount, address token) external onlyOwner {
        ContractEscrow storage ce = escrows[escrowId];
        require(ce.exists, "no escrow");
        uint256 serviceFee = (principalAmount * FEE_PERCENTAGE) / 10000; // Calculate 5% fee
        uint256 totalAmount = principalAmount + serviceFee; // Total to be deposited
        ce.milestones[ce.milestoneCount] = Milestone(totalAmount, token, EscrowStatus.None, serviceFee);
        ce.milestoneCount++;
        ce.totalAmount += totalAmount; // Total includes principal + fee
    }

    // deposit in native or ERC20
    function deposit(bytes32 escrowId, uint256 milestoneIndex, bytes calldata txRef) external payable nonReentrant {
        ContractEscrow storage ce = escrows[escrowId];
        require(ce.exists, "no escrow");
        Milestone storage ms = ce.milestones[milestoneIndex];
        require(ms.status == EscrowStatus.None, "already funded");
        // Check minimum deposit requirement
        if (minDepositAmounts[ms.token] > 0) {
            require(ms.amount >= minDepositAmounts[ms.token], "amount below min");
        }

        if (ms.token == address(0)) {
            require(msg.value == ms.amount, "incorrect amount");
        } else {
            IERC20(ms.token).transferFrom(msg.sender, address(this), ms.amount);
        }
        ms.status = EscrowStatus.Deposited;
        emit Deposited(escrowId, milestoneIndex, ms.amount, ms.token, msg.sender, txRef);
    }

    // client approves release
    function release(bytes32 escrowId, uint256 milestoneIndex) external nonReentrant {
        ContractEscrow storage ce = escrows[escrowId];
        require(ce.exists, "no escrow");
        require(msg.sender == ce.client, "only client");
        Milestone storage ms = ce.milestones[milestoneIndex];
        require(ms.status == EscrowStatus.Deposited || ms.status == EscrowStatus.Disputed, "not fundable");
        ms.status = EscrowStatus.Released;
        
        // Calculate amounts (ms.amount is total deposited, which includes principal + fee)
        uint256 principalAmount = ms.amount - ms.serviceFee;
        uint256 feeAmount = ms.serviceFee;
        
        // Transfer principal to freelancer
        _transferOut(ms.token, ce.developer, principalAmount);
        
        // Transfer fee to treasury
        _transferOut(ms.token, treasuryWallet, feeAmount);
        
        emit Released(escrowId, milestoneIndex, principalAmount, feeAmount, ms.token, ce.developer, treasuryWallet);
    }

    // developer or client can raise dispute
    function raiseDispute(bytes32 escrowId, uint256 milestoneIndex, string calldata reason) external {
        ContractEscrow storage ce = escrows[escrowId];
        require(ce.exists, "no escrow");
        Milestone storage ms = ce.milestones[milestoneIndex];
        require(ms.status == EscrowStatus.Deposited, "not in deposit");
        ms.status = EscrowStatus.Disputed;
        ce.disputed = true;
        emit Disputed(escrowId, milestoneIndex, msg.sender, reason);
    }

    // admin/multisig override: resolve dispute either refund or release
    function adminResolveRelease(bytes32 escrowId, uint256 milestoneIndex) external onlyOwner nonReentrant {
        ContractEscrow storage ce = escrows[escrowId];
        Milestone storage ms = ce.milestones[milestoneIndex];
        require(ms.status == EscrowStatus.Disputed, "not disputed");
        ms.status = EscrowStatus.Released;
        
        // Calculate amounts (ms.amount is total deposited, which includes principal + fee)
        uint256 principalAmount = ms.amount - ms.serviceFee;
        uint256 feeAmount = ms.serviceFee;
        
        // Transfer principal to freelancer
        _transferOut(ms.token, ce.developer, principalAmount);
        
        // Transfer fee to treasury
        _transferOut(ms.token, treasuryWallet, feeAmount);
        
        emit Released(escrowId, milestoneIndex, principalAmount, feeAmount, ms.token, ce.developer, treasuryWallet);
    }

    function adminResolveRefund(bytes32 escrowId, uint256 milestoneIndex) external onlyOwner nonReentrant {
        ContractEscrow storage ce = escrows[escrowId];
        Milestone storage ms = ce.milestones[milestoneIndex];
        require(ms.status == EscrowStatus.Disputed, "not disputed");
        ms.status = EscrowStatus.Refunded;
        // Refund full amount (principal + fee) to client
        _transferOut(ms.token, ce.client, ms.amount);
        emit Refunded(escrowId, milestoneIndex, ms.amount, ms.token, ce.client);
    }

    function _transferOut(address token, address to, uint256 amount) internal {
        if (token == address(0)) {
            (bool success, ) = to.call{value: amount}("");
            require(success, "transfer failed");
        } else {
            IERC20(token).transfer(to, amount);
        }
    }

    // Public view functions for testing
    function getEscrowMilestoneCount(bytes32 escrowId) external view returns (uint256) {
        return escrows[escrowId].milestoneCount;
    }

    function getEscrowTotalAmount(bytes32 escrowId) external view returns (uint256) {
        return escrows[escrowId].totalAmount;
    }

    // fallback to accept ETH
    receive() external payable {}
}