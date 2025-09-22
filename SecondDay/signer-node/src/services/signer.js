const { ethers } = require('ethers');

class SignerService {
  constructor() {
    this.signer = null;
    this.provider = null;
    this.initialized = false;
  }

  initialize() {
    if (this.initialized) return;

    try {
      // 创建提供者
      this.provider = new ethers.JsonRpcProvider(process.env.SEPOLIA_RPC_URL);
      
      // 创建签名者
      this.signer = new ethers.Wallet(process.env.SIGNER_PRIVATE_KEY, this.provider);
      
      this.initialized = true;
      console.log('✅ Signer service initialized');
      console.log('📝 Signer address:', this.signer.address);
    } catch (error) {
      console.error('❌ Signer service initialization failed:', error);
      throw error;
    }
  }

  async generateSignature(userAddress, tokenAddress, amount, nonce, expireAt) {
    this.initialize();

    try {
      // 创建消息哈希（与合约中的相同）
      const messageHash = ethers.solidityPackedKeccak256(
        ['address', 'address', 'uint256', 'uint256', 'uint256'],
        [userAddress, tokenAddress, amount, nonce, expireAt]
      );

      // 生成签名 - 直接签名原始哈希，避免双重前缀问题
      const signature = await this.signer.signHash(messageHash);
      
      console.log('📝 Generated signature for:', {
        userAddress,
        tokenAddress,
        amount: amount.toString(),
        nonce: nonce.toString(),
        expireAt: expireAt.toString(),
        messageHash,
        signature
      });

      return {
        signature,
        messageHash,
        signer: this.signer.address,
        userAddress,
        tokenAddress,
        amount: amount.toString(),
        nonce: nonce.toString(),
        expireAt: expireAt.toString(),
        timestamp: Date.now()
      };
    } catch (error) {
      console.error('Error generating signature:', error);
      throw error;
    }
  }

  async verifySignature(userAddress, tokenAddress, amount, nonce, signature) {
    this.initialize();

    try {
      // 重新创建消息哈希
      const messageHash = ethers.solidityPackedKeccak256(
        ['address', 'address', 'uint256', 'uint256'],
        [userAddress, tokenAddress, amount, nonce]
      );

      // 恢复签名者地址 - 从原始哈希验证
      const recoveredAddress = ethers.recoverAddress(messageHash, signature);
      
      // 验证签名者是否是预期的地址
      const isValid = recoveredAddress.toLowerCase() === this.signer.address.toLowerCase();
      
      console.log('🔍 Signature verification:', {
        messageHash,
        expectedSigner: this.signer.address,
        recoveredSigner: recoveredAddress,
        isValid
      });

      return {
        isValid,
        recoveredAddress,
        expectedAddress: this.signer.address,
        messageHash
      };
    } catch (error) {
      console.error('Error verifying signature:', error);
      throw error;
    }
  }

  // 生成随机 nonce
  generateNonce() {
    return Math.floor(Math.random() * 1000000000);
  }

  // 获取签名者地址
  getSignerAddress() {
    this.initialize();
    return this.signer.address;
  }
}

module.exports = new SignerService();
