'use client';

import { useState, useEffect } from 'react';
import { useAccount, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseUnits } from 'viem';
import { useWalletInfo } from '../store/wallet';
import { CONTRACTS, API_CONFIG } from '../lib/contracts';
import { createPublicClient, http } from 'viem';
import { sepolia } from 'viem/chains';

interface SignatureData {
  signature: string;
  messageHash: string;
  signer: string;
  userAddress: string;
  tokenAddress: string;
  amount: string;
  nonce: string;
  timestamp: number;
  expireAt?: number;
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
  const [pollingCount, setPollingCount] = useState(0);
  const [errorMessage, setErrorMessage] = useState('');

  const { writeContract, data: hash, error: writeError } = useWriteContract();
  
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({
    hash,
  });

  // 创建公共客户端用于查询交易状态
  const publicClient = createPublicClient({
    chain: sepolia,
    transport: http('https://sepolia.gateway.tenderly.co')
  });

  // 手动查询交易状态
  const checkTransactionStatus = async (txHash: string) => {
    try {
      const receipt = await publicClient.getTransactionReceipt({
        hash: txHash as `0x${string}`
      });
      
      if (receipt.status === 'success') {
        setStep('success');
        return true;
      } else if (receipt.status === 'reverted') {
        alert('交易已确认但执行失败，请检查交易详情');
        setStep('input');
        return false;
      }
    } catch (error) {
      console.error('查询交易状态失败:', error);
      // 如果查询失败，可能是交易还在pending，继续等待
      return null;
    }
  };

  // 轮询检查交易状态
  useEffect(() => {
    let intervalId: NodeJS.Timeout | null = null;
    
    if (step === 'claiming' && hash) {
      let pollCount = 0;
      const maxPolls = 60; // 最多轮询60次 (5分钟)
      
      intervalId = setInterval(async () => {
        pollCount++;
        setPollingCount(pollCount);
        
        try {
          const receipt = await publicClient.getTransactionReceipt({
            hash: hash as `0x${string}`
          });
          
          if (receipt.status === 'success') {
            setStep('success');
            if (intervalId) clearInterval(intervalId);
          } else if (receipt.status === 'reverted') {
            alert('交易失败，请重试');
            setStep('input');
            if (intervalId) clearInterval(intervalId);
          }
        } catch {
          // 交易还在pending，继续轮询
          console.log(`轮询 ${pollCount}/${maxPolls}: 交易还在处理中...`);
        }
        
        // 达到最大轮询次数后停止
        if (pollCount >= maxPolls) {
          console.log('轮询超时，但交易可能仍在处理中');
          if (intervalId) clearInterval(intervalId);
        }
      }, 5000); // 每5秒检查一次
    }
    
    return () => {
      if (intervalId) clearInterval(intervalId);
    };
  }, [step, hash, publicClient]);

  // 监听交易错误（包括用户取消）
  useEffect(() => {
    if (writeError && step === 'claiming') {
      console.error('交易错误:', writeError);
      let errorMsg = '交易失败';
      
      const errorMessage = writeError.message || '';
      
      if (errorMessage.includes('User rejected') || 
          errorMessage.includes('user denied') || 
          errorMessage.includes('User denied') ||
          errorMessage.includes('user rejected') ||
          errorMessage.includes('rejected')) {
        errorMsg = '用户取消了交易';
        setStep('signed'); // 恢复到签名状态
      } else if (errorMessage.includes('insufficient funds')) {
        errorMsg = '账户 ETH 余额不足，无法支付 gas 费';
        setStep('signed');
      } else if (errorMessage.includes('nonce')) {
        errorMsg = '此代币已被领取过或 nonce 无效';
        setStep('input'); // 回到输入状态
      } else if (errorMessage.includes('expired')) {
        errorMsg = '签名已过期，请重新生成';
        setStep('input');
      } else if (errorMessage) {
        errorMsg = '交易失败: ' + errorMessage;
        setStep('signed');
      }
      
      setErrorMessage(errorMsg);
      // 对于用户取消，不显示为错误状态，直接恢复
      if (!errorMessage.includes('rejected') && !errorMessage.includes('denied')) {
        // 只有非用户取消的错误才显示错误页面
        setTimeout(() => {
          alert(errorMsg);
        }, 100);
      }
    }
  }, [writeError, step]);

  // 监听wagmi的交易状态变化（作为备用）
  useEffect(() => {
    if (isConfirmed && step === 'claiming') {
      setStep('success');
    }
  }, [isConfirmed, step]);

  // 生成签名
  const generateSignature = async () => {
    if (!address || !selectedToken || !amount) return;

    setLoading(true);
    try {
      // 使用正确的小数位数计算金额
      const decimals = selectedToken.decimals;
      const adjustedAmount = parseUnits(amount, decimals);

      // 计算过期时间（当前时间 + 5分钟）
      const expireAt = Math.floor(Date.now() / 1000) + 300;

      const response = await fetch(`${API_CONFIG.BASE_URL}${API_CONFIG.ENDPOINTS.GENERATE_SIGNATURE}`, {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({
          userAddress: address,
          tokenAddress: selectedToken.address,
          amount: adjustedAmount.toString(),
          expireAt: expireAt.toString(),
        }),
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const data = await response.json();   
      console.log(data,'dataa')
      if (data.data.signature) {
        setSignatureData({
          ...data.data,
          expireAt: expireAt
        });
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

  const claimTokens = () => {
    if (!signatureData || !address) return;

    setStep('claiming');
    
    try {
      writeContract({
        address: CONTRACTS.TOKEN_AIRDROP.address,
        abi: CONTRACTS.TOKEN_AIRDROP.abi,
        functionName: 'claimTokens',
        args: [
          signatureData.tokenAddress as `0x${string}`,
          BigInt(signatureData.amount),
          BigInt(signatureData.nonce),
          BigInt(signatureData.expireAt || 0),
          signatureData.signature as `0x${string}`,
        ],
        gas: BigInt(300000), // 设置 gas limit
      });
    } catch (error: unknown) {
      console.error('领取代币失败:', error);
      let errorMsg = '领取代币失败';
      
      const errorMessage = error instanceof Error ? error.message : String(error);
      
      if (errorMessage.includes('insufficient funds')) {
        errorMsg = '账户 ETH 余额不足，无法支付 gas 费';
      } else if (errorMessage.includes('user rejected')) {
        errorMsg = '用户取消了交易';
      } else if (errorMessage.includes('nonce')) {
        errorMsg = '此代币已被领取过';
      } else if (errorMessage.includes('expired')) {
        errorMsg = '签名已过期，请重新生成';
      } else if (errorMessage) {
        errorMsg = errorMessage;
      }
      
      alert(errorMsg);
      setStep('signed');
    }
  };

  // 重置状态
  const resetForm = () => {
    setStep('input');
    setSignatureData(null);
    setAmount('');
    setErrorMessage('');
    setPollingCount(0);
  };

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
          <p className="text-gray-600 dark:text-gray-300 mb-2">
            {isConfirming ? '等待交易确认...' : '正在提交交易...'}
          </p>
          {pollingCount > 0 && (
            <p className="text-sm text-blue-600 dark:text-blue-400 mb-4">
              自动检查进度: {pollingCount}/60 (每5秒检查一次)
            </p>
          )}
          {hash && (
            <div className="space-y-3">
              <p className="text-xs text-gray-500 dark:text-gray-400">
                交易哈希: {hash.slice(0, 10)}...{hash.slice(-8)}
              </p>
              <p className="text-sm text-gray-600 dark:text-gray-400">
                系统正在自动检查交易状态，无需手动操作
              </p>
              <div className="flex space-x-3 justify-center">
                <button
                  onClick={() => checkTransactionStatus(hash)}
                  className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-4 rounded-md transition-colors text-sm"
                >
                  🔍 立即检查
                </button>
                <button
                  onClick={() => setStep('success')}
                  className="bg-green-600 hover:bg-green-700 text-white font-medium py-2 px-4 rounded-md transition-colors text-sm"
                >
                  ✅ 手动确认成功
                </button>
              </div>
            </div>
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

      {errorMessage && step === 'signed' && (
        <div className="mt-4 bg-yellow-50 dark:bg-yellow-900/20 rounded-md p-4">
          <p className="text-sm text-yellow-800 dark:text-yellow-300">
            {errorMessage}
          </p>
          <button 
            onClick={() => setErrorMessage('')}
            className="mt-2 text-xs text-yellow-600 dark:text-yellow-400 hover:underline"
          >
            关闭提示
          </button>
        </div>
      )}
    </div>
  );
}