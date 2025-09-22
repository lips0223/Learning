const express = require('express');
const router = express.Router();
const signatureController = require('../controllers/signatures');

// 生成签名
router.post('/generate', signatureController.generateSignature);

// 验证签名
router.post('/verify', signatureController.verifySignature);

// 获取签名者信息
router.get('/signer', signatureController.getSignerInfo);

module.exports = router;
