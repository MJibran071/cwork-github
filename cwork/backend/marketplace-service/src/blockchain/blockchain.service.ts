import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ethers } from 'ethers';
import { EscrowStatus, EscrowActionDto, CreateEscrowDto, AddMilestoneDto } from './dto/blockchain.dto';

@Injectable()
export class BlockchainService {
  private readonly logger = new Logger(BlockchainService.name);
  private provider: ethers.JsonRpcProvider;
  private escrowContract: ethers.Contract;
  private wallet: ethers.Wallet;
  private isMockMode: boolean = false;

  constructor(private configService: ConfigService) {
    this.initializeProvider();
  }

  private initializeProvider() {
    try {
      const rpcUrl = this.configService.get<string>('BLOCKCHAIN_RPC_URL');
      const privateKey = this.configService.get<string>('BLOCKCHAIN_PRIVATE_KEY');
      const contractAddress = this.configService.get<string>('ESCROW_CONTRACT_ADDRESS');

      if (!rpcUrl || !privateKey || !contractAddress) {
        this.logger.warn('Blockchain configuration missing. Running in mock mode.');
        this.isMockMode = true;
        return;
      }

      this.provider = new ethers.JsonRpcProvider(rpcUrl);
      this.wallet = new ethers.Wallet(privateKey, this.provider);
      
      // Load ABI from contract artifacts
      const contractAbi = [
        "function createEscrow(bytes32 escrowId, address client, address developer) external",
        "function addMilestone(bytes32 escrowId, uint256 principalAmount, address token) external",
        "function deposit(bytes32 escrowId, uint256 milestoneIndex, bytes calldata txRef) external payable",
        "function release(bytes32 escrowId, uint256 milestoneIndex) external",
        "function raiseDispute(bytes32 escrowId, uint256 milestoneIndex, string calldata reason) external",
        "function adminResolveRelease(bytes32 escrowId, uint256 milestoneIndex) external",
        "function adminResolveRefund(bytes32 escrowId, uint256 milestoneIndex) external",
        "function getEscrowMilestoneCount(bytes32 escrowId) external view returns (uint256)",
        "function getEscrowTotalAmount(bytes32 escrowId) external view returns (uint256)",
        "event EscrowCreated(bytes32 indexed escrowId, address client, address developer)",
        "event Deposited(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 amount, address token, address depositor, bytes txRef)",
        "event Released(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 principalAmount, uint256 feeAmount, address token, address toFreelancer, address toTreasury)",
        "event Disputed(bytes32 indexed escrowId, uint256 milestoneIndex, address raisedBy, string reason)",
        "event Refunded(bytes32 indexed escrowId, uint256 milestoneIndex, uint256 amount, address token, address to)"
      ];

      this.escrowContract = new ethers.Contract(contractAddress, contractAbi, this.wallet);
      this.logger.log('Blockchain provider initialized successfully');
    } catch (error) {
      this.logger.error('Failed to initialize blockchain provider', error);
      this.isMockMode = true;
    }
  }

  async createEscrow(createEscrowDto: CreateEscrowDto): Promise<string> {
    const { escrowId, client, developer } = createEscrowDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Creating escrow ${escrowId} for client ${client} and developer ${developer}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.createEscrow(escrowId, client, developer);
      await tx.wait();
      this.logger.log(`Escrow created: ${escrowId}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to create escrow', error);
      throw new Error('Failed to create escrow on blockchain');
    }
  }

  async addMilestone(addMilestoneDto: AddMilestoneDto): Promise<string> {
    const { escrowId, principalAmount, token } = addMilestoneDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Adding milestone to escrow ${escrowId} with amount ${principalAmount} and token ${token}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.addMilestone(escrowId, principalAmount, token);
      await tx.wait();
      this.logger.log(`Milestone added to escrow: ${escrowId}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to add milestone', error);
      throw new Error('Failed to add milestone on blockchain');
    }
  }

  async deposit(escrowActionDto: EscrowActionDto): Promise<string> {
    const { escrowId, milestoneIndex, txRef } = escrowActionDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Depositing to escrow ${escrowId}, milestone ${milestoneIndex}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.deposit(escrowId, milestoneIndex, txRef);
      await tx.wait();
      this.logger.log(`Deposit completed for escrow: ${escrowId}, milestone: ${milestoneIndex}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to deposit', error);
      throw new Error('Failed to deposit on blockchain');
    }
  }

  async release(escrowActionDto: EscrowActionDto): Promise<string> {
    const { escrowId, milestoneIndex } = escrowActionDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Releasing escrow ${escrowId}, milestone ${milestoneIndex}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.release(escrowId, milestoneIndex);
      await tx.wait();
      this.logger.log(`Escrow released: ${escrowId}, milestone: ${milestoneIndex}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to release escrow', error);
      throw new Error('Failed to release escrow on blockchain');
    }
  }

  async raiseDispute(escrowActionDto: EscrowActionDto): Promise<string> {
    const { escrowId, milestoneIndex, reason } = escrowActionDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Raising dispute for escrow ${escrowId}, milestone ${milestoneIndex}, reason: ${reason}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.raiseDispute(escrowId, milestoneIndex, reason);
      await tx.wait();
      this.logger.log(`Dispute raised: ${escrowId}, milestone: ${milestoneIndex}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to raise dispute', error);
      throw new Error('Failed to raise dispute on blockchain');
    }
  }

  async adminResolveRelease(escrowActionDto: EscrowActionDto): Promise<string> {
    const { escrowId, milestoneIndex } = escrowActionDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Admin resolving release for escrow ${escrowId}, milestone ${milestoneIndex}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.adminResolveRelease(escrowId, milestoneIndex);
      await tx.wait();
      this.logger.log(`Admin resolved release: ${escrowId}, milestone: ${milestoneIndex}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to admin resolve release', error);
      throw new Error('Failed to admin resolve release on blockchain');
    }
  }

  async adminResolveRefund(escrowActionDto: EscrowActionDto): Promise<string> {
    const { escrowId, milestoneIndex } = escrowActionDto;
    
    if (this.isMockMode) {
      this.logger.log(`Mock: Admin resolving refund for escrow ${escrowId}, milestone ${milestoneIndex}`);
      return 'mock-tx-hash';
    }

    try {
      const tx = await this.escrowContract.adminResolveRefund(escrowId, milestoneIndex);
      await tx.wait();
      this.logger.log(`Admin resolved refund: ${escrowId}, milestone: ${milestoneIndex}`);
      return tx.hash;
    } catch (error) {
      this.logger.error('Failed to admin resolve refund', error);
      throw new Error('Failed to admin resolve refund on blockchain');
    }
  }

  async getEscrowMilestoneCount(escrowId: string): Promise<number> {
    if (this.isMockMode) {
      return 1; // Mock value
    }

    try {
      const count = await this.escrowContract.getEscrowMilestoneCount(escrowId);
      return Number(count);
    } catch (error) {
      this.logger.error('Failed to get milestone count', error);
      throw new Error('Failed to get milestone count from blockchain');
    }
  }

  async getEscrowTotalAmount(escrowId: string): Promise<number> {
    if (this.isMockMode) {
      return 1000; // Mock value
    }

    try {
      const amount = await this.escrowContract.getEscrowTotalAmount(escrowId);
      return Number(amount);
    } catch (error) {
      this.logger.error('Failed to get total amount', error);
      throw new Error('Failed to get total amount from blockchain');
    }
  }

  computeEscrowId(contractId: string): string {
    return ethers.keccak256(ethers.toUtf8Bytes(contractId));
  }
}