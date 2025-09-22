const signerService = require('../services/signer');
const firebaseService = require('../services/firebase');

// 生成空投签名
const generateSignature = async (req, res) => {
  try {
    const { userAddress, tokenAddress, amount, expireAt } = req.body;

    // 参数验证
    if (!userAddress || !tokenAddress || !amount || !expireAt) {
      return res.status(400).json({ 
        error: 'Missing required parameters',
        required: ['userAddress', 'tokenAddress', 'amount', 'expireAt']
      });
    }

    // 生成 nonce
    const nonce = signerService.generateNonce();

    // 生成签名
    const signatureData = await signerService.generateSignature(
      userAddress,
      tokenAddress,
      amount,
      nonce,
      expireAt
    );

    // 保存签名到数据库
    const savedSignature = await firebaseService.saveSignature({
      userAddress: userAddress.toLowerCase(),
      tokenAddress,
      amount: amount.toString(),
      nonce: nonce.toString(),
      expireAt: expireAt.toString(),
      signature: signatureData.signature,
      messageHash: signatureData.messageHash,
      signer: signatureData.signer,
      used: false
    });

    res.json({
      message: 'Signature generated successfully',
      data: {
        signature: signatureData.signature,
        messageHash: signatureData.messageHash,
        signer: signatureData.signer,
        userAddress,
        tokenAddress,
        amount: amount.toString(),
        nonce: nonce.toString(),
        expireAt: expireAt.toString(),
        id: savedSignature.id
      }
    });
  } catch (error) {
    console.error('Generate signature error:', error);
    res.status(500).json({ 
      error: 'Failed to generate signature',
      details: error.message 
    });
  }
};

// 验证签名
const verifySignature = async (req, res) => {
  try {
    const { userAddress, tokenAddress, amount, nonce, signature } = req.body;

    // 参数验证
    if (!userAddress || !tokenAddress || !amount || !nonce || !signature) {
      return res.status(400).json({ 
        error: 'Missing required parameters',
        required: ['userAddress', 'tokenAddress', 'amount', 'nonce', 'signature']
      });
    }

    // 验证签名
    const verification = await signerService.verifySignature(
      userAddress,
      tokenAddress,
      amount,
      nonce,
      signature
    );

    res.json({
      message: 'Signature verification completed',
      isValid: verification.isValid,
      verification
    });
  } catch (error) {
    console.error('Verify signature error:', error);
    res.status(500).json({ 
      error: 'Failed to verify signature',
      details: error.message 
    });
  }
};

// 获取签名者信息
const getSignerInfo = async (req, res) => {
  try {
    const signerAddress = signerService.getSignerAddress();
    
    res.json({
      message: 'Signer info retrieved successfully',
      signer: {
        address: signerAddress,
        contractAddress: process.env.TOKEN_AIRDROP_ADDRESS
      }
    });
  } catch (error) {
    console.error('Get signer info error:', error);
    res.status(500).json({ 
      error: 'Failed to get signer info',
      details: error.message 
    });
  }
};

module.exports = {
  generateSignature,
  verifySignature,
  getSignerInfo
};
