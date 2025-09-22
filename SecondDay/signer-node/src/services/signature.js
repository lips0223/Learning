const { ethers } = require('ethers');

class SignatureService {
  constructor() {
    this.signerPrivateKey = process.env.SIGNER_PRIVATE_KEY;
    this.tokenAirDropAddress = process.env.TOKEN_AIRDROP_ADDRESS;
    
    if (!this.signerPrivateKey) {
      throw new Error('SIGNER_PRIVATE_KEY not configured');
    }
    
    this.wallet = new ethers.Wallet(this.signerPrivateKey);
    console.log('🔑 Signer wallet initialized:', this.wallet.address);
  }

  /**
   * 生成空投签名
   * @param {string} recipient - 接收者地址
   * @param {string} tokenAddress - 代币合约地址
   * @param {string} amount - 空投数量
   * @param {number} nonce - 防重放nonce
   * @returns {Object} 签名信息
   */
  async generateAirDropSignature(recipient, tokenAddress, amount, nonce) {
    try {
      // 构造消息哈希 (需要与合约中的哈希方式一致)
      const messageHash = ethers.solidityPackedKeccak256(
        ['address', 'address', 'uint256', 'uint256'],
        [recipient, tokenAddress, amount, nonce]
      );

      // 生成签名
      const signature = await this.wallet.signMessage(ethers.getBytes(messageHash));
      
      // 分解签名
      const { r, s, v } = ethers.Signature.from(signature);

      return {
        recipient,
        tokenAddress,
        amount: amount.toString(),
        nonce,
        messageHash,
        signature,
        r,
        s,
        v,
        signer: this.wallet.address,
        timestamp: new Date().toISOString()
      };
    } catch (error) {
      console.error('Signature generation failed:', error);
      throw new Error(`Failed to generate signature: ${error.message}`);
    }
  }

  /**
   * 验证签名
   * @param {Object} signatureData - 签名数据
   * @returns {boolean} 验证结果
   */
  verifySignature(signatureData) {
    try {
      const { recipient, tokenAddress, amount, nonce, signature } = signatureData;
      
      // 重新构造消息哈希
      const messageHash = ethers.solidityPackedKeccak256(
        ['address', 'address', 'uint256', 'uint256'],
        [recipient, tokenAddress, amount, nonce]
      );

      // 恢复签名者地址
      const recoveredAddress = ethers.verifyMessage(ethers.getBytes(messageHash), signature);
      
      // 验证签名者是否为预期的地址
      return recoveredAddress.toLowerCase() === this.wallet.address.toLowerCase();
    } catch (error) {
      console.error('Signature verification failed:', error);
      return false;
    }
  }

  /**
   * 获取签名者地址
   * @returns {string} 签名者地址
   */
  getSignerAddress() {
    return this.wallet.address;
  }
}

module.exports = SignatureService;
