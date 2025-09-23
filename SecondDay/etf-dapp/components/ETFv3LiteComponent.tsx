'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useReadContracts, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { CONTRACT_ADDRESSES } from '../lib/contracts';
import { ETFv3Lite_ABI, ERC20_ABI } from '../lib/abis';

// 代币详情接口
interface TokenDetail {
  address: string;
  symbol: string;
  balance: bigint;
  required: bigint;
  allowance: bigint;
}

const ETFv3LiteComponent = () => {
  const { address, isConnected } = useAccount();
  const [mode, setMode] = useState<'invest' | 'redeem' | 'investETH' | 'redeemETH' | 'investLock' | 'investETHLock'>('invest');
  const [amount, setAmount] = useState('');
  const [ethAmount, setEthAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);

  // 读取ETF基本信息
  const { data: etfInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'name',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'symbol',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'totalSupply',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'getTokens',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'lockDuration',
      },
    ],
  });

  // 读取用户相关信息
  const { data: userInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'balanceOf',
        args: address ? [address] : undefined,
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'lockEndTime',
        args: address ? [address] : undefined,
      },
      {
        address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
        abi: ETFv3Lite_ABI,
        functionName: 'canRedeem',
        args: address ? [address] : undefined,
      },
    ],
  });

  // 获取投资所需代币数量
  const { data: investAmounts } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
    abi: ETFv3Lite_ABI,
    functionName: 'getInvestTokenAmounts',
    args: amount ? [parseEther(amount)] : [0n],
  });

  // 获取赎回将得到的代币数量
  const { data: redeemAmounts } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
    abi: ETFv3Lite_ABI,
    functionName: 'getRedeemTokenAmounts',
    args: amount ? [parseEther(amount)] : [0n],
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
        args: address ? [address, CONTRACT_ADDRESSES.ETFv3Lite] : undefined,
      },
    ]).flat() || [],
  });

  // 更新代币详情
  useEffect(() => {
    if (tokens && tokenBalances && investAmounts) {
      const details: TokenDetail[] = tokens.map((tokenAddress, index) => {
        const baseIndex = index * 3;
        return {
          address: tokenAddress,
          symbol: tokenBalances[baseIndex]?.result as string || 'Unknown',
          balance: tokenBalances[baseIndex + 1]?.result as bigint || 0n,
          required: (investAmounts as bigint[])[index] || 0n,
          allowance: tokenBalances[baseIndex + 2]?.result as bigint || 0n,
        };
      });
      setTokenDetails(details);
    }
  }, [tokens, tokenBalances, investAmounts]);

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
            args: [CONTRACT_ADDRESSES.ETFv3Lite, token.required * 2n],
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
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'invest',
      args: [parseEther(amount)],
    });
  };

  // 锁定投资函数
  const handleInvestWithLock = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'investWithLock',
      args: [parseEther(amount)],
    });
  };

  // ETH投资函数  
  const handleInvestWithETH = () => {
    if (!ethAmount) return;
    
    const swapPaths: `0x${string}`[] = [];
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 1800);
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'investWithETH',
      args: [swapPaths, deadline],
      value: parseEther(ethAmount),
    });
  };

  // ETH锁定投资函数
  const handleInvestWithETHAndLock = () => {
    if (!ethAmount) return;
    
    const swapPaths: `0x${string}`[] = [];
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 1800);
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'investWithETHAndLock',
      args: [swapPaths, deadline],
      value: parseEther(ethAmount),
    });
  };

  // 赎回函数
  const handleRedeem = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'redeem',
      args: [parseEther(amount)],
    });
  };

  // ETH赎回函数
  const handleRedeemWithETH = () => {
    if (!amount) return;
    
    const swapPaths: `0x${string}`[] = [];
    const deadline = BigInt(Math.floor(Date.now() / 1000) + 1800);
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv3Lite as `0x${string}`,
      abi: ETFv3Lite_ABI,
      functionName: 'redeemWithETH',
      args: [parseEther(amount), swapPaths, deadline],
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

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* ETF基本信息 */}
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
        <h2 className="text-2xl font-bold mb-4">
          {etfInfo?.[0]?.result as string} ({etfInfo?.[1]?.result as string})
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-4 gap-4">
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
            <p className="text-gray-600">锁定期</p>
            <p className="text-lg font-semibold">
              {lockDuration ? Number(lockDuration) / 86400 : 0} 天
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
          >
            普通投资
          </button>
          <button
            onClick={() => setMode('investLock')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'investLock' ? 'bg-purple-500 text-white' : 'bg-gray-200'
            }`}
          >
            锁定投资
          </button>
          <button
            onClick={() => setMode('investETH')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'investETH' ? 'bg-blue-500 text-white' : 'bg-gray-200'
            }`}
          >
            ETH投资
          </button>
          <button
            onClick={() => setMode('investETHLock')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'investETHLock' ? 'bg-purple-500 text-white' : 'bg-gray-200'
            }`}
          >
            ETH锁定投资
          </button>
          <button
            onClick={() => setMode('redeem')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'redeem' ? 'bg-green-500 text-white' : 'bg-gray-200'
            }`}
            disabled={!canRedeem}
          >
            代币赎回
          </button>
          <button
            onClick={() => setMode('redeemETH')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'redeemETH' ? 'bg-green-500 text-white' : 'bg-gray-200'
            }`}
            disabled={!canRedeem}
          >
            ETH赎回
          </button>
        </div>

        {/* 投资界面 */}
        {(mode === 'invest' || mode === 'redeem' || mode === 'investLock') && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {mode === 'redeem' ? '赎回数量' : '投资数量'}
              </label>
              <input
                type="number"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                className="w-full px-3 py-2 border border-gray-300 rounded-md"
                placeholder="输入ETF数量"
              />
            </div>

            {mode === 'investLock' && (
              <div className="p-4 bg-purple-50 rounded-lg">
                <p className="text-sm text-purple-800">
                  <strong>锁定投资:</strong> 您的资产将被锁定 {lockDuration ? Number(lockDuration) / 86400 : 0} 天，
                  锁定期间无法赎回，但可能享受额外收益。
                </p>
              </div>
            )}

            {/* 代币详情 */}
            {tokenDetails.length > 0 && (
              <div className="space-y-2">
                <h3 className="font-medium">成分代币:</h3>
                {tokenDetails.map((token, index) => (
                  <div key={token.address} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                    <span>{token.symbol}</span>
                    <div className="text-right">
                      <p className="text-sm">
                        余额: {formatEther(token.balance)}
                      </p>
                      <p className="text-sm">
                        {mode === 'redeem' ? '将得到' : '需要'}: {formatEther(mode === 'redeem' ? (redeemAmounts as bigint[])?.[index] || 0n : token.required)}
                      </p>
                      {mode !== 'redeem' && (
                        <p className="text-xs">
                          授权: {formatEther(token.allowance)}
                          {token.allowance < token.required && (
                            <span className="text-red-500 ml-1">需要授权</span>
                          )}
                        </p>
                      )}
                    </div>
                  </div>
                ))}
              </div>
            )}

            {mode !== 'redeem' && (
              <button
                onClick={handleBatchApprove}
                disabled={isApproving || !tokenDetails.some(t => t.allowance < t.required)}
                className="w-full bg-yellow-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
              >
                {isApproving ? '授权中...' : '批量授权'}
              </button>
            )}

            <button
              onClick={
                mode === 'invest' ? handleInvest 
                : mode === 'investLock' ? handleInvestWithLock
                : handleRedeem
              }
              disabled={isPending || isConfirming || !amount || (mode === 'redeem' && !canRedeem)}
              className={`w-full py-2 px-4 rounded-lg text-white ${
                mode === 'redeem' ? 'bg-green-500' 
                : mode === 'investLock' ? 'bg-purple-500'
                : 'bg-blue-500'
              } disabled:bg-gray-300`}
            >
              {isPending || isConfirming 
                ? '处理中...' 
                : mode === 'invest' ? '普通投资'
                : mode === 'investLock' ? '锁定投资'
                : '赎回'
              }
            </button>
          </div>
        )}

        {/* ETH投资界面 */}
        {(mode === 'investETH' || mode === 'redeemETH' || mode === 'investETHLock') && (
          <div className="space-y-4">
            {mode === 'redeemETH' ? (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  赎回ETF数量
                </label>
                <input
                  type="number"
                  value={amount}
                  onChange={(e) => setAmount(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="输入ETF数量"
                />
              </div>
            ) : (
              <div>
                <label className="block text-sm font-medium text-gray-700 mb-2">
                  ETH投资数量
                </label>
                <input
                  type="number"
                  value={ethAmount}
                  onChange={(e) => setEthAmount(e.target.value)}
                  className="w-full px-3 py-2 border border-gray-300 rounded-md"
                  placeholder="输入ETH数量"
                />
              </div>
            )}

            {mode === 'investETHLock' && (
              <div className="p-4 bg-purple-50 rounded-lg">
                <p className="text-sm text-purple-800">
                  <strong>ETH锁定投资:</strong> 您的ETH将转换为ETF并锁定 {lockDuration ? Number(lockDuration) / 86400 : 0} 天。
                </p>
              </div>
            )}

            <div className="p-4 bg-yellow-50 rounded-lg">
              <p className="text-sm text-yellow-800">
                <strong>注意:</strong> ETH投资功能需要通过Uniswap V3进行代币交换。
                当前为简化版本，实际使用需要配置正确的交换路径。
              </p>
            </div>

            <button
              onClick={
                mode === 'investETH' ? handleInvestWithETH
                : mode === 'investETHLock' ? handleInvestWithETHAndLock
                : handleRedeemWithETH
              }
              disabled={
                isPending || isConfirming || 
                (mode === 'redeemETH' ? (!amount || !canRedeem) : !ethAmount)
              }
              className={`w-full py-2 px-4 rounded-lg text-white ${
                mode === 'redeemETH' ? 'bg-green-500'
                : mode === 'investETHLock' ? 'bg-purple-500'
                : 'bg-blue-500'
              } disabled:bg-gray-300`}
            >
              {isPending || isConfirming 
                ? '处理中...' 
                : mode === 'investETH' ? '用ETH投资'
                : mode === 'investETHLock' ? 'ETH锁定投资'
                : '赎回为ETH'
              }
            </button>
          </div>
        )}

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

export default ETFv3LiteComponent;