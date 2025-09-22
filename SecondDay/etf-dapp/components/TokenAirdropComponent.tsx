'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { useWalletInfo } from '../store/wallet';
import { CONTRACTS, API_CONFIG } from '../lib/contracts';

interface SignatureData {
  signature: string;
  messageHash: string;
  signer: string;
  userAddress: string;
  tokenAddress: string;
  amount: string;
  nonce: string;
  timestamp: number;
}

const TOKEN_OPTIONS = [
  { address: CONTRACTS.MOCK_TOKENS.WBTC.address, symbol: 'nWBTC', name: 'New Mock Wrapped Bitcoin', decimals: 8 },
  { address: CONTRACTS.MOCK_TOKENS.USDC.address, symbol: 'nUSDC', name: 'New Mock USD Coin', decimals: 6 },
  { address: CONTRACTS.MOCK_TOKENS.USDT.address, symbol: 'nUSDT', name: 'New Mock Tether USD', decimals: 6 },
  { address: CONTRACTS.MOCK_TOKENS.LINK.address, symbol: 'nLINK', name: 'New Mock Chainlink Token', decimals: 18 },
  { address: CONTRACTS.MOCK_TOKENS.UNI.address, symbol: 'nWETH', name: 'New Mock Wrapped Ether', decimals: 18 },
];

export function TokenAirdropComponent() {
  const { address } = useAccount();
  const { isConnected, isCorrectNetwork } = useWalletInfo();
  
  const [selectedToken, setSelectedToken] = useState(TOKEN_OPTIONS[0]);
  const [amount, setAmount] = useState('');
  const [loading, setLoading] = useState(false);
  const [signatureData, setSignatureData] = useState<SignatureData | null>(null);
  const [step, setStep] = useState<'input' | 'signed' | 'claiming' | 'success'>('input');

  const { writeContract, data: hash, error: writeError } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // 生成签名
  const generateSignature = async () => {
    if (!address || !selectedToken || !amount) return;

    setLoading(true);
    try {
      // 计算以代币小数位数表示的金额
      const decimals = selectedToken.decimals;
      const amountInWei = parseEther(amount);
      // 对于非18位小数的代币，需要调整
      const adjustedAmount = decimals === 18 
        ? amountInWei 
        : BigInt(amount) * BigInt(10 ** decimals);

      // 生成随机 nonce
      const nonce = Math.floor(Math.random() * 1000000000);

      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.GENERATE_SIGNATURE}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userAddress: address,
          tokenAddress: selectedToken.address,
          amount: adjustedAmount.toString(),
          nonce: nonce,
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();
      
      if (data.signature) {
        setSignatureData(data);
        setStep('signed');
      } else {
        throw new Error('签名生成失败');
      }
    } catch (error) {
      console.error('生成签名失败:', error);
      alert('生成签名失败: ' + (error as Error).message);
    } finally {
      setLoading(false);
    }
  };

  const claimTokens = async () => {
    if (!signatureData || !address) return;

    setStep('claiming');
    
    try {
      // 计算过期时间（当前时间 + 5分钟）
      const expireAt = Math.floor(Date.now() / 1000) + 300; // 5分钟后过期

      await writeContract({
        address: CONTRACTS.TOKEN_AIRDROP.address,
        abi: CONTRACTS.TOKEN_AIRDROP.abi,
        functionName: 'claimTokens',
        args: [
          signatureData.tokenAddress as `0x${string}`,
          BigInt(signatureData.amount),
          BigInt(signatureData.nonce),
          BigInt(expireAt),
          signatureData.signature as `0x${string}`,
        ],
      });
    } catch (error) {
      console.error('领取代币失败:', error);
      alert('领取代币失败: ' + (error as Error).message);
      setStep('signed');
    }
  };

  // 重置状态
  const resetForm = () => {
    setStep('input');
    setSignatureData(null);
    setAmount('');
  };

  // 监听交易确认
  useEffect(() => {
    if (isConfirmed && step === 'claiming') {
      setStep('success');
    }
  }, [isConfirmed, step]);

  if (!isConnected || !isCorrectNetwork) {
    return (
      <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
        <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">
          代币空投
        </h3>
        <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-md p-4">
          <p className="text-sm text-yellow-800 dark:text-yellow-300">
            {!isConnected ? '请先连接钱包' : '请切换到 Sepolia 测试网络'}
          </p>
        </div>
      </div>
    );
  }

  return (
    <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
      <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-6">
        代币空投领取
      </h3>

      {step === 'input' && (
        <div className="space-y-4">
          {/* 代币选择 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              选择代币
            </label>
            <select
              value={selectedToken.address}
              onChange={(e) => {
                const token = TOKEN_OPTIONS.find(t => t.address === e.target.value);
                if (token) setSelectedToken(token);
              }}
              className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
            >
              {TOKEN_OPTIONS.map((token) => (
                <option key={token.address} value={token.address}>
                  {token.symbol} - {token.name}
                </option>
              ))}
            </select>
          </div>

          {/* 数量输入 */}
          <div>
            <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
              领取数量
            </label>
            <input
              type="number"
              value={amount}
              onChange={(e) => setAmount(e.target.value)}
              placeholder={`输入 ${selectedToken.symbol} 数量`}
              className="w-full p-3 border border-gray-300 dark:border-gray-600 rounded-md bg-white dark:bg-gray-700 text-gray-900 dark:text-white"
              step="0.000001"
              min="0"
            />
          </div>

          <button
            onClick={generateSignature}
            disabled={!amount || loading}
            className="w-full bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-medium py-3 px-4 rounded-md transition-colors"
          >
            {loading ? '生成签名中...' : '生成签名'}
          </button>
        </div>
      )}

      {step === 'signed' && signatureData && (
        <div className="space-y-4">
          <div className="bg-green-50 dark:bg-green-900/20 rounded-md p-4">
            <h4 className="text-sm font-medium text-green-800 dark:text-green-300 mb-2">
              签名生成成功！
            </h4>
            <div className="text-xs text-green-700 dark:text-green-400 space-y-1">
              <p><strong>代币:</strong> {selectedToken.symbol}</p>
              <p><strong>数量:</strong> {formatEther(BigInt(signatureData.amount))}</p>
              <p><strong>签名者:</strong> {signatureData.signer}</p>
            </div>
          </div>

          <div className="flex space-x-3">
            <button
              onClick={claimTokens}
              className="flex-1 bg-green-600 hover:bg-green-700 text-white font-medium py-3 px-4 rounded-md transition-colors"
            >
              领取代币
            </button>
            <button
              onClick={resetForm}
              className="flex-1 bg-gray-600 hover:bg-gray-700 text-white font-medium py-3 px-4 rounded-md transition-colors"
            >
              重新开始
            </button>
          </div>
        </div>
      )}

      {step === 'claiming' && (
        <div className="text-center py-8">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-600 mx-auto mb-4"></div>
          <p className="text-gray-600 dark:text-gray-300">
            {isConfirming ? '等待交易确认...' : '正在提交交易...'}
          </p>
          {hash && (
            <p className="text-xs text-gray-500 dark:text-gray-400 mt-2">
              交易哈希: {hash.slice(0, 10)}...{hash.slice(-8)}
            </p>
          )}
        </div>
      )}

      {step === 'success' && (
        <div className="text-center py-8">
          <div className="w-16 h-16 bg-green-100 dark:bg-green-900/20 rounded-full flex items-center justify-center mx-auto mb-4">
            <svg className="w-8 h-8 text-green-600 dark:text-green-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
            </svg>
          </div>
          <h4 className="text-lg font-medium text-gray-900 dark:text-white mb-2">
            领取成功！
          </h4>
          <p className="text-gray-600 dark:text-gray-300 mb-4">
            {amount} {selectedToken.symbol} 已成功领取到您的钱包
          </p>
          <button
            onClick={resetForm}
            className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 rounded-md transition-colors"
          >
            再次领取
          </button>
        </div>
      )}

      {writeError && (
        <div className="mt-4 bg-red-50 dark:bg-red-900/20 rounded-md p-4">
          <p className="text-sm text-red-800 dark:text-red-300">
            错误: {writeError.message}
          </p>
        </div>
      )}
    </div>
  );
}