import { Controller, Post, Body } from '@nestjs/common';
import { Web3Service } from './web3.service';
import { Web3LoginDto } from '../types';

@Controller('web3')
export class Web3Controller {
  constructor(private readonly web3Service: Web3Service) {}

  @Post('generate-nonce')
  generateNonce(@Body() body: { address: string }) {
    const nonce = this.web3Service.generateNonce();
    const message = this.web3Service.generateLoginMessage(body.address, nonce);
    return { nonce, message };
  }

  @Post('verify-signature')
  async verifySignature(@Body() web3LoginDto: Web3LoginDto) {
    const isValid = await this.web3Service.verifySignature(web3LoginDto);
    return { valid: isValid };
  }
}
