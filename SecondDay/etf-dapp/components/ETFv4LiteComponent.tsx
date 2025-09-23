'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useReadContracts, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { CONTRACT_ADDRESSES } from '../lib/contracts';
import { ETFv4Lite_ABI, ERC20_ABI } from '../lib/abis';

// 代币详情接口
interface TokenDetail {
  address: string;
  symbol: string;
  decimals: number;
  balance: bigint;
  allowance: bigint;
  required: bigint;
}

export default function ETFv4LiteComponent() {
  const { address, isConnected } = useAccount();
  const [etfAmount, setEtfAmount] = useState('');
  const [tokens, setTokens] = useState<TokenDetail[]>([]);
  const [isInvestMode, setIsInvestMode] = useState(true);

  // 读取ETF基本信息
  const { data: etfName } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite,
    abi: ETFv4Lite_ABI,
    functionName: 'name',
  });

  const { data: etfSymbol } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite,
    abi: ETFv4Lite_ABI,
    functionName: 'symbol',
  });

  const { data: etfBalance, refetch: refetchEtfBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite,
    abi: ETFv4Lite_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  // 删除不存在的minMintAmount读取
  // const { data: minMintAmount } = useReadContract({
  //   address: CONTRACT_ADDRESSES.ETFv1,
  //   abi: ETFv1_ABI,
  //   functionName: 'minMintAmount',
  // });

  // 读取成分代币地址
  const { data: tokenAddresses } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite,
    abi: ETFv4Lite_ABI,
    functionName: 'getTokenAddresses',
  });

  // 计算所需代币数量 - 暂时注释以修复编译错误
  // const { data: requiredAmounts } = useReadContract({
  //   address: CONTRACT_ADDRESSES.ETFv1,
  //   abi: ETFv1_ABI,
  //   functionName: 'getInvestTokenAmounts',
  //   args: etfAmount ? [parseEther(etfAmount)] : undefined,
  // });

  // 读取代币详情
  const tokenDetailsContracts = (tokenAddresses as string[])?.flatMap((tokenAddress) => [
    {
      address: tokenAddress as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'symbol',
    },
    {
      address: tokenAddress as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'decimals',
    },
    {
      address: tokenAddress as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'balanceOf',
      args: address ? [address] : undefined,
    },
    {
      address: tokenAddress as `0x${string}`,
      abi: ERC20_ABI,
      functionName: 'allowance',
      args: address ? [address, CONTRACT_ADDRESSES.ETFv1] : undefined,
    },
  ]) || [];

  const { data: tokenDetailsData } = useReadContracts({
    contracts: tokenDetailsContracts,
  });

  // 处理代币数据
  useEffect(() => {
    if (tokenAddresses && tokenDetailsData) {
      const tokensPerAddress = 4; // symbol, decimals, balance, allowance
      const processedTokens: TokenDetail[] = (tokenAddresses as string[]).map((address, index) => {
        const baseIndex = index * tokensPerAddress;
        const symbol = tokenDetailsData[baseIndex]?.result as string || 'Unknown';
        const decimals = tokenDetailsData[baseIndex + 1]?.result as number || 18;
        const balance = tokenDetailsData[baseIndex + 2]?.result as bigint || BigInt(0);
        const allowance = tokenDetailsData[baseIndex + 3]?.result as bigint || BigInt(0);
        const required = BigInt(0); // 暂时使用默认值

        return {
          address,
          symbol,
          decimals,
          balance,
          allowance,
          required,
        };
      });
      setTokens(processedTokens);
    }
  }, [tokenAddresses, tokenDetailsData]);

  // 写入合约
  const { writeContract, data: hash, isPending } = useWriteContract();

  // 等待交易确认
  const { isLoading: isConfirming, isSuccess } = useWaitForTransactionReceipt({
    hash,
  });

  // 交易成功后刷新余额
  useEffect(() => {
    if (isSuccess) {
      refetchEtfBalance();
    }
  }, [isSuccess, refetchEtfBalance]);

  // 授权代币
  const handleApprove = async (tokenAddress: string, amount: bigint) => {
    try {
      writeContract({
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'approve',
        args: [CONTRACT_ADDRESSES.ETFv1, amount],
      });
    } catch (error) {
      console.error('Approval failed:', error);
    }
  };

  // 投资ETF
  const handleInvest = async () => {
    if (!etfAmount) return;
    
    try {
      // ETFv1的invest函数接受代币数量数组
      const amounts = tokens.map(token => token.required);
      writeContract({
        address: CONTRACT_ADDRESSES.ETFv4Lite,
        abi: ETFv4Lite_ABI,
        functionName: 'invest',
        args: [amounts],
      });
    } catch (error) {
      console.error('Investment failed:', error);
    }
  };

  // 赎回ETF
  const handleRedeem = async () => {
    if (!etfAmount) return;
    
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFv4Lite,
        abi: ETFv4Lite_ABI,
        functionName: 'redeem',
        args: [parseEther(etfAmount)],
      });
    } catch (error) {
      console.error('Redemption failed:', error);
    }
  };

  if (!isConnected) {
    return (
      <div className="text-center py-8">
        <p className="text-gray-600 dark:text-gray-300">请先连接钱包</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto space-y-6">
      {/* ETF信息卡片 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <h2 className="text-2xl font-bold text-gray-900 dark:text-white mb-4">
          {etfName} ({etfSymbol})
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <p className="text-sm text-gray-600 dark:text-gray-400">我的ETF余额</p>
            <p className="text-xl font-semibold text-gray-900 dark:text-white">
              {etfBalance ? formatEther(etfBalance) : '0'} {etfSymbol}
            </p>
          </div>
          <div>
            <p className="text-sm text-gray-600 dark:text-gray-400">最小投资金额</p>
            <p className="text-xl font-semibold text-gray-900 dark:text-white">
              1.0 {etfSymbol}
            </p>
          </div>
        </div>
      </div>

      {/* 操作模式切换 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg shadow-md p-6">
        <div className="flex space-x-4 mb-6">
          <button
            onClick={() => setIsInvestMode(true)}
            className={`px-4 py-2 rounded-md font-medium ${
              isInvestMode
                ? 'bg-blue-500 text-white'
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
            }`}
          >
            投资
          </button>
          <button
            onClick={() => setIsInvestMode(false)}
            className={`px-4 py-2 rounded-md font-medium ${
              !isInvestMode
                ? 'bg-blue-500 text-white'
                : 'bg-gray-200 dark:bg-gray-700 text-gray-700 dark:text-gray-300'
            }`}
          >
            赎回
          </button>
        </div>

        {/* 金额输入 */}
        <div className="mb-6">
          <label className="block text-sm font-medium text-gray-700 dark:text-gray-300 mb-2">
            {isInvestMode ? '投资金额' : '赎回金额'} ({etfSymbol})
          </label>
          <input
            type="number"
            step="0.01"
            value={etfAmount}
            onChange={(e) => setEtfAmount(e.target.value)}
            className="w-full px-3 py-2 border border-gray-300 dark:border-gray-600 rounded-md shadow-sm focus:outline-none focus:ring-blue-500 focus:border-blue-500 dark:bg-gray-700 dark:text-white"
            placeholder={`输入${isInvestMode ? '投资' : '赎回'}金额`}
          />
        </div>

        {/* 代币详情 */}
        {isInvestMode && tokens.length > 0 && (
          <div className="mb-6">
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-4">
              所需代币
            </h3>
            <div className="space-y-3">
              {tokens.map((token) => {
                const requiredFormatted = formatEther(token.required);
                const balanceFormatted = formatEther(token.balance);
                const hasEnoughBalance = token.balance >= token.required;
                const hasEnoughAllowance = token.allowance >= token.required;
                
                return (
                  <div key={token.address} className="flex items-center justify-between p-3 bg-gray-50 dark:bg-gray-700 rounded-md">
                    <div className="flex-1">
                      <div className="flex items-center space-x-2">
                        <span className="font-medium text-gray-900 dark:text-white">
                          {token.symbol}
                        </span>
                        <span className="text-sm text-gray-600 dark:text-gray-400">
                          需要: {requiredFormatted}
                        </span>
                      </div>
                      <div className="text-sm text-gray-600 dark:text-gray-400">
                        余额: {balanceFormatted} | 
                        授权: {formatEther(token.allowance)}
                      </div>
                    </div>
                    <div className="flex items-center space-x-2">
                      {!hasEnoughBalance && (
                        <span className="text-red-500 text-sm">余额不足</span>
                      )}
                      {hasEnoughBalance && !hasEnoughAllowance && (
                        <button
                          onClick={() => handleApprove(token.address, token.required)}
                          disabled={isPending}
                          className="px-3 py-1 bg-blue-500 text-white rounded text-sm hover:bg-blue-600 disabled:opacity-50"
                        >
                          授权
                        </button>
                      )}
                      {hasEnoughBalance && hasEnoughAllowance && (
                        <span className="text-green-500 text-sm">✓ 就绪</span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>
          </div>
        )}

        {/* 操作按钮 */}
        <div className="flex justify-center">
          {isInvestMode ? (
            <button
              onClick={handleInvest}
              disabled={
                isPending || 
                isConfirming || 
                !etfAmount || 
                tokens.some(token => token.balance < token.required || token.allowance < token.required)
              }
              className="px-6 py-2 bg-green-500 text-white rounded-md hover:bg-green-600 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending || isConfirming ? '交易中...' : '投资ETF'}
            </button>
          ) : (
            <button
              onClick={handleRedeem}
              disabled={
                isPending || 
                isConfirming || 
                !etfAmount || 
                Boolean(etfBalance && parseEther(etfAmount) > etfBalance)
              }
              className="px-6 py-2 bg-red-500 text-white rounded-md hover:bg-red-600 disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {isPending || isConfirming ? '交易中...' : '赎回ETF'}
            </button>
          )}
        </div>

        {/* 交易状态 */}
        {hash && (
          <div className="mt-4 p-3 bg-blue-50 dark:bg-blue-900/20 rounded-md">
            <p className="text-sm text-blue-700 dark:text-blue-300">
              交易已提交: {hash}
            </p>
            {isConfirming && <p className="text-sm text-blue-600">等待确认中...</p>}
            {isSuccess && <p className="text-sm text-green-600">交易成功！</p>}
          </div>
        )}
      </div>
    </div>
  );
}