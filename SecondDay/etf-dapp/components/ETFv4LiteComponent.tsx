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
  balance: bigint;
  required: bigint;
  allowance: bigint;
  price: bigint;
}

const ETFv4LiteComponent = () => {
  const { address, isConnected } = useAccount();
  const [mode, setMode] = useState<'invest' | 'redeem' | 'investETH' | 'redeemETH' | 'investLock' | 'investETHLock' | 'priceCheck'>('invest');
  const [amount, setAmount] = useState('');
  const [maxPricePerShare, setMaxPricePerShare] = useState('');
  const [isApproving, setIsApproving] = useState(false);

  // 读取ETF基本信息
  const { data: etfInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'name',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'symbol',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'totalSupply',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'getTokens',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'lockDuration',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'paused',
      },
    ],
  });

  // 读取价格和价值信息
  const { data: priceInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'getTotalValue',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'getSharePrice',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'priceOracle',
      },
    ],
  });

  // 读取用户相关信息
  const { data: userInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'lockEndTime',
        args: address ? [address] : undefined,
      },
      {
        address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
        abi: ETFv4Lite_ABI,
        functionName: 'canRedeem',
        args: address ? [address] : undefined,
      },
    ],
  });

  // 获取投资所需代币数量
  const { data: investAmounts } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
    abi: ETFv4Lite_ABI,
    functionName: 'getInvestTokenAmounts',
    args: amount ? [parseEther(amount)] : [BigInt(0)],
  });

  // 获取赎回将得到的代币数量
  const { data: redeemAmounts } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
    abi: ETFv4Lite_ABI,
    functionName: 'getRedeemTokenAmounts',
    args: amount ? [parseEther(amount)] : [BigInt(0)],
  });

  // 获取代币详情
  const [tokenDetails, setTokenDetails] = useState<TokenDetail[]>([]);

  // 读取代币详情
  const tokens = etfInfo?.[3]?.result as string[] | undefined;

  const { data: tokenBalances } = useReadContracts({
    contracts: tokens?.map(tokenAddress => [
      {
        address: tokenAddress as `0x${string}`,
        abi: ERC20_ABI,
        functionName: 'symbol',
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
        args: address ? [address, CONTRACT_ADDRESSES.ETFv4Lite] : undefined,
      },
    ]).flat() || [],
  });

  // 读取代币价格
  const { data: tokenPrices } = useReadContracts({
    contracts: tokens?.map(tokenAddress => ({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'getTokenPrice',
      args: [tokenAddress],
    })) || [],
  });

  // 更新代币详情
  useEffect(() => {
    if (tokens && tokenBalances && investAmounts && tokenPrices) {
      const details: TokenDetail[] = tokens.map((tokenAddress, index) => {
        const baseIndex = index * 3;
        return {
          address: tokenAddress,
          symbol: tokenBalances[baseIndex]?.result as string || 'Unknown',
          balance: tokenBalances[baseIndex + 1]?.result as bigint || BigInt(0),
          required: (investAmounts as bigint[])[index] || BigInt(0),
          allowance: tokenBalances[baseIndex + 2]?.result as bigint || BigInt(0),
          price: tokenPrices[index]?.result as bigint || BigInt(0),
        };
      });
      setTokenDetails(details);
    }
  }, [tokens, tokenBalances, investAmounts, tokenPrices]);

  // 合约写入hooks
  const { writeContract, data: hash, error, isPending } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = 
    useWaitForTransactionReceipt({ hash });

  // 时间格式化函数
  const formatTime = (timestamp: bigint) => {
    const date = new Date(Number(timestamp) * 1000);
    return date.toLocaleString();
  };

  // 计算剩余锁定时间
  const getLockTimeRemaining = () => {
    if (!userInfo?.[1]?.result) return null;
    const lockEndTime = userInfo[1].result as bigint;
    const currentTime = BigInt(Math.floor(Date.now() / 1000));
    
    if (lockEndTime <= currentTime) return null;
    
    const remainingSeconds = Number(lockEndTime - currentTime);
    const days = Math.floor(remainingSeconds / 86400);
    const hours = Math.floor((remainingSeconds % 86400) / 3600);
    const minutes = Math.floor((remainingSeconds % 3600) / 60);
    
    return `${days}天 ${hours}小时 ${minutes}分钟`;
  };

  // 批量授权函数
  const handleBatchApprove = async () => {
    if (!tokenDetails.length) return;
    setIsApproving(true);
    
    try {
      for (const token of tokenDetails) {
        if (token.allowance < token.required) {
          writeContract({
            address: token.address as `0x${string}`,
            abi: ERC20_ABI,
            functionName: 'approve',
            args: [CONTRACT_ADDRESSES.ETFv4Lite, token.required * BigInt(2)],
          });
          
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }
    } catch (error) {
      console.error('批量授权失败:', error);
    } finally {
      setIsApproving(false);
    }
  };

  // 投资函数
  const handleInvest = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'invest',
      args: [parseEther(amount)],
    });
  };

  // 价格保护投资
  const handleInvestWithPriceCheck = () => {
    if (!amount || !maxPricePerShare) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'investWithPriceCheck',
      args: [parseEther(amount), parseEther(maxPricePerShare)],
    });
  };

  // 锁定投资函数
  const handleInvestWithLock = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'investWithLock',
      args: [parseEther(amount)],
    });
  };

  // 赎回函数
  const handleRedeem = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'redeem',
      args: [parseEther(amount)],
    });
  };

  // 紧急暂停
  const handleEmergencyPause = () => {
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'emergencyPause',
      args: [],
    });
  };

  // 解除暂停
  const handleEmergencyUnpause = () => {
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv4Lite as `0x${string}`,
      abi: ETFv4Lite_ABI,
      functionName: 'emergencyUnpause',
      args: [],
    });
  };

  if (!isConnected) {
    return (
      <div className="text-center p-8">
        <p className="text-gray-600">请先连接钱包</p>
      </div>
    );
  }

  const userBalance = userInfo?.[0]?.result as bigint;
  const lockEndTime = userInfo?.[1]?.result as bigint;
  const canRedeem = userInfo?.[2]?.result as boolean;
  const lockDuration = etfInfo?.[4]?.result as bigint;
  const isPaused = etfInfo?.[5]?.result as boolean;
  const totalValue = priceInfo?.[0]?.result as bigint;
  const sharePrice = priceInfo?.[1]?.result as bigint;
  const priceOracle = priceInfo?.[2]?.result as string;

  return (
    <div className="max-w-5xl mx-auto p-6">
      {/* ETF基本信息 */}
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
        <h2 className="text-2xl font-bold mb-4">
          {etfInfo?.[0]?.result as string} ({etfInfo?.[1]?.result as string})
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-4">
          <div>
            <p className="text-gray-600">总供应量</p>
            <p className="text-lg font-semibold">
              {etfInfo?.[2]?.result ? formatEther(etfInfo[2].result as bigint) : '0'} ETF
            </p>
          </div>
          <div>
            <p className="text-gray-600">我的余额</p>
            <p className="text-lg font-semibold">
              {userBalance ? formatEther(userBalance) : '0'} ETF
            </p>
          </div>
          <div>
            <p className="text-gray-600">总价值(ETH)</p>
            <p className="text-lg font-semibold">
              {totalValue ? formatEther(totalValue) : '0'} ETH
            </p>
          </div>
          <div>
            <p className="text-gray-600">每份价格</p>
            <p className="text-lg font-semibold">
              {sharePrice ? formatEther(sharePrice) : '0'} ETH
            </p>
          </div>
        </div>

        {/* 系统状态 */}
        <div className="mt-4 grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <p className="text-gray-600">系统状态</p>
            <p className={`text-lg font-semibold ${isPaused ? 'text-red-600' : 'text-green-600'}`}>
              {isPaused ? '🚨 已暂停' : '✅ 正常运行'}
            </p>
          </div>
          <div>
            <p className="text-gray-600">价格预言机</p>
            <p className="text-sm font-mono">
              {priceOracle ? `${priceOracle.slice(0, 6)}...${priceOracle.slice(-4)}` : 'N/A'}
            </p>
          </div>
          <div>
            <p className="text-gray-600">赎回状态</p>
            <p className={`text-lg font-semibold ${canRedeem ? 'text-green-600' : 'text-red-600'}`}>
              {canRedeem ? '可赎回' : '锁定中'}
            </p>
          </div>
        </div>
      </div>

      {/* 代币价格信息 */}
      {tokenDetails.length > 0 && (
        <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
          <h3 className="text-xl font-bold mb-4">📊 成分代币实时价格</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
            {tokenDetails.map((token) => (
              <div key={token.address} className="p-4 bg-gradient-to-r from-blue-50 to-purple-50 rounded-lg">
                <div className="flex justify-between items-center">
                  <h4 className="font-semibold text-lg">{token.symbol}</h4>
                  <div className="text-right">
                    <p className="text-lg font-bold text-blue-600">
                      {token.price ? formatEther(token.price) : '0'} ETH
                    </p>
                    <p className="text-sm text-gray-600">
                      余额: {formatEther(token.balance)}
                    </p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      )}

      {/* 暂停警告 */}
      {isPaused && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4 mb-6">
          <h3 className="font-medium text-red-800 mb-2">⚠️ 系统已暂停</h3>
          <p className="text-red-700 text-sm">
            系统目前处于暂停状态，所有投资和赎回操作已被禁用。请等待管理员恢复系统运行。
          </p>
        </div>
      )}

      {/* 锁定状态信息 */}
      {lockEndTime && Number(lockEndTime) > Date.now() / 1000 && (
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4 mb-6">
          <h3 className="font-medium text-yellow-800 mb-2">🔒 资产锁定中</h3>
          <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
            <div>
              <p className="text-yellow-700">锁定结束时间:</p>
              <p className="font-medium">{formatTime(lockEndTime)}</p>
            </div>
            <div>
              <p className="text-yellow-700">剩余时间:</p>
              <p className="font-medium">{getLockTimeRemaining()}</p>
            </div>
          </div>
        </div>
      )}

      {/* 操作模式选择 */}
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
        <div className="flex flex-wrap gap-2 mb-4">
          <button
            onClick={() => setMode('invest')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'invest' ? 'bg-blue-500 text-white' : 'bg-gray-200'
            }`}
            disabled={isPaused}
          >
            普通投资
          </button>
          <button
            onClick={() => setMode('priceCheck')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'priceCheck' ? 'bg-indigo-500 text-white' : 'bg-gray-200'
            }`}
            disabled={isPaused}
          >
            价格保护投资
          </button>
          <button
            onClick={() => setMode('investLock')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'investLock' ? 'bg-purple-500 text-white' : 'bg-gray-200'
            }`}
            disabled={isPaused}
          >
            锁定投资
          </button>
          <button
            onClick={() => setMode('redeem')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'redeem' ? 'bg-green-500 text-white' : 'bg-gray-200'
            }`}
            disabled={!canRedeem || isPaused}
          >
            普通赎回
          </button>
        </div>

        {/* 普通投资界面 */}
        {mode === 'invest' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                投资数量
              </label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                placeholder="输入ETF数量"
              />
            </div>

            {/* 代币详情 */}
            {tokenDetails.length > 0 && (
              <div className="space-y-2">
                <h3 className="font-medium">需要的成分代币:</h3>
                {tokenDetails.map((token) => (
                  <div key={token.address} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                    <span>{token.symbol}</span>
                    <div className="text-right">
                      <p className="text-sm">
                        余额: {formatEther(token.balance)}
                      </p>
                      <p className="text-sm">
                        需要: {formatEther(token.required)}
                      </p>
                      <p className="text-xs">
                        授权: {formatEther(token.allowance)}
                        {token.allowance < token.required && (
                          <span className="text-red-500 ml-1">需要授权</span>
                        )}
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <button
              onClick={handleBatchApprove}
              disabled={isApproving || !tokenDetails.some(t => t.allowance < t.required)}
              className="w-full bg-yellow-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
            >
              {isApproving ? '授权中...' : '批量授权'}
            </button>

            <button
              onClick={handleInvest}
              disabled={isPending || isConfirming || !amount || isPaused}
              className="w-full bg-blue-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
            >
              {isPending || isConfirming ? '处理中...' : '投资'}
            </button>
          </div>
        )}

        {/* 价格保护投资界面 */}
        {mode === 'priceCheck' && (
          <div className="space-y-4">
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  投资数量
                </label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="输入ETF数量"
                />
              </div>
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  最大每份价格 (ETH)
                </label>
                <input
                  type="number"
                  step="0.0001"
                  value={maxPricePerShare}
                  onChange={(e) => setMaxPricePerShare(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="最大可接受价格"
                />
              </div>
            </div>

            <div className="p-4 bg-indigo-50 rounded-lg">
              <p className="text-sm text-indigo-800">
                <strong>价格保护:</strong> 当前每份价格为 {sharePrice ? formatEther(sharePrice) : '0'} ETH。
                如果实际价格超过您设置的最大价格，交易将失败以保护您的资产。
              </p>
            </div>

            <button
              onClick={handleInvestWithPriceCheck}
              disabled={isPending || isConfirming || !amount || !maxPricePerShare || isPaused}
              className="w-full bg-indigo-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
            >
              {isPending || isConfirming ? '处理中...' : '价格保护投资'}
            </button>
          </div>
        )}

        {/* 锁定投资界面 */}
        {mode === 'investLock' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                锁定投资数量
              </label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                placeholder="输入ETF数量"
              />
            </div>

            <div className="p-4 bg-purple-50 rounded-lg">
              <p className="text-sm text-purple-800">
                <strong>锁定投资:</strong> 您的资产将被锁定 {lockDuration ? Number(lockDuration) / 86400 : 0} 天，
                锁定期间无法赎回，但可能享受额外收益。
              </p>
            </div>

            <button
              onClick={handleInvestWithLock}
              disabled={isPending || isConfirming || !amount || isPaused}
              className="w-full bg-purple-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
            >
              {isPending || isConfirming ? '处理中...' : '锁定投资'}
            </button>
          </div>
        )}

        {/* 赎回界面 */}
        {mode === 'redeem' && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                赎回数量
              </label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                placeholder="输入ETF数量"
              />
            </div>

            {/* 赎回预览 */}
            {tokenDetails.length > 0 && redeemAmounts && (
              <div className="space-y-2">
                <h3 className="font-medium">将获得的代币:</h3>
                {tokenDetails.map((token, index) => (
                  <div key={token.address} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                    <span>{token.symbol}</span>
                    <div className="text-right">
                      <p className="text-sm">
                        将得到: {formatEther((redeemAmounts as bigint[])[index] || BigInt(0))}
                      </p>
                      <p className="text-xs">
                        价值: {token.price && redeemAmounts ? 
                          formatEther(token.price * ((redeemAmounts as bigint[])[index] || BigInt(0)) / BigInt(10)**BigInt(18)) : '0'} ETH
                      </p>
                    </div>
                  </div>
                ))}
              </div>
            )}

            <button
              onClick={handleRedeem}
              disabled={isPending || isConfirming || !amount || !canRedeem || isPaused}
              className="w-full bg-green-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
            >
              {isPending || isConfirming ? '处理中...' : '赎回'}
            </button>
          </div>
        )}

        {/* 管理员紧急控制 */}
        <div className="mt-6 pt-6 border-t border-gray-200">
          <h3 className="text-lg font-medium mb-4">🚨 紧急控制 (仅管理员)</h3>
          <div className="flex gap-2">
            <button
              onClick={handleEmergencyPause}
              disabled={isPending || isConfirming || isPaused}
              className="px-4 py-2 bg-red-500 text-white rounded-lg disabled:bg-gray-300"
            >
              紧急暂停
            </button>
            <button
              onClick={handleEmergencyUnpause}
              disabled={isPending || isConfirming || !isPaused}
              className="px-4 py-2 bg-green-500 text-white rounded-lg disabled:bg-gray-300"
            >
              解除暂停
            </button>
          </div>
        </div>

        {/* 交易状态 */}
        {hash && (
          <div className="mt-4 p-4 bg-blue-50 rounded-lg">
            <p className="text-sm">
              交易哈希: {hash}
            </p>
            {isConfirming && <p className="text-sm">等待确认...</p>}
            {isConfirmed && <p className="text-sm text-green-600">交易成功!</p>}
          </div>
        )}

        {error && (
          <div className="mt-4 p-4 bg-red-50 rounded-lg">
            <p className="text-sm text-red-600">错误: {error.message}</p>
          </div>
        )}
      </div>
    </div>
  );
};

export default ETFv4LiteComponent;