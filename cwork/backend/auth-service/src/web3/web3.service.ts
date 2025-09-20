import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { ethers } from 'ethers';
import { Web3LoginDto } from '../types';

@Injectable()
export class Web3Service {
  constructor(private configService: ConfigService) {}

  async verifySignature(web3LoginDto: Web3LoginDto): Promise<boolean> {
    const { address, signature, nonce } = web3LoginDto;

    try {
      // Generate the expected message
      const expectedMessage = this.generateLoginMessage(address, nonce);

      // Recover the address from the signature
      const recoveredAddress = ethers.verifyMessage(expectedMessage, signature);

      // Check if the recovered address matches the provided address
      return recoveredAddress.toLowerCase() === address.toLowerCase();
    } catch (error) {
      return false;
    }
  }

  generateLoginMessage(address: string, nonce: string): string {
    return `Please sign this message to authenticate with Cwork. Address: ${address}, Nonce: ${nonce}`;
  }

  generateNonce(): string {
    return (
      Math.random().toString(36).substring(2, 15) + Math.random().toString(36).substring(2, 15)
    );
  }
}
