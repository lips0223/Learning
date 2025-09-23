'use client';

import { useState, useEffect } from 'react';
import { useAccount, useReadContract, useReadContracts, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { formatEther, parseEther } from 'viem';
import { CONTRACT_ADDRESSES } from '../lib/contracts';
import { ETFv2_ABI, ERC20_ABI } from '../lib/abis';

// 代币详情接口
interface TokenDetail {
  address: string;
  symbol: string;
  balance: bigint;
  required: bigint;
  allowance: bigint;
}

const ETFv2Component = () => {
  const { address, isConnected } = useAccount();
  const [mode, setMode] = useState<'invest' | 'redeem' | 'investETH' | 'redeemETH'>('invest');
  const [amount, setAmount] = useState('');
  const [ethAmount, setEthAmount] = useState('');
  const [isApproving, setIsApproving] = useState(false);

  // 读取ETF基本信息
  const { data: etfInfo } = useReadContracts({
    contracts: [
      {
        address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
        abi: ETFv2_ABI,
        functionName: 'name',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
        abi: ETFv2_ABI,
        functionName: 'symbol',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
        abi: ETFv2_ABI,
        functionName: 'totalSupply',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
        abi: ETFv2_ABI,
        functionName: 'getTokenAddresses',
      },
      {
        address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
        abi: ETFv2_ABI,
        functionName: 'getTokenWeights',
      },
    ],
  });

  // 读取用户ETF余额
  const { data: userBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
    abi: ETFv2_ABI,
    functionName: 'balanceOf',
    args: address ? [address] : undefined,
  });

  // 注意：ETH余额通过钱包直接获取，不需要通过合约读取

  // 获取投资所需代币数量 - 暂时注释以修复编译错误
  // const { data: investAmounts } = useReadContract({
  //   address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
  //   abi: ETFv2_ABI,
  //   functionName: 'getInvestTokenAmounts',
  //   args: amount ? [parseEther(amount)] : [0n],
  // });

  // 获取赎回将得到的代币数量 - 暂时注释以修复编译错误
  // const { data: redeemAmounts } = useReadContract({
  //   address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
  //   abi: ETFv2_ABI,
  //   functionName: 'getRedeemTokenAmounts',
  //   args: amount ? [parseEther(amount)] : [0n],
  // });

  // 获取代币详情
  const [tokenDetails, setTokenDetails] = useState<TokenDetail[]>([]);

  // 读取代币详情
  const tokens = etfInfo?.[3]?.result as string[] | undefined;
  const weights = etfInfo?.[4]?.result as bigint[] | undefined;

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
        args: address ? [address, CONTRACT_ADDRESSES.ETFv2] : undefined,
      },
    ]).flat() || [],
  });

  // 更新代币详情
  useEffect(() => {
    if (tokens && tokenBalances && weights) {
      const details: TokenDetail[] = tokens.map((tokenAddress, index) => {
        const baseIndex = index * 3;
        return {
          address: tokenAddress,
          symbol: tokenBalances[baseIndex]?.result as string || 'Unknown',
          balance: tokenBalances[baseIndex + 1]?.result as bigint || BigInt(0),
          required: BigInt(0), // 暂时使用默认值
          allowance: tokenBalances[baseIndex + 2]?.result as bigint || BigInt(0),
        };
      });
      setTokenDetails(details);
    }
  }, [tokens, tokenBalances, weights]);

  // 合约写入hooks
  const { writeContract, data: hash, error, isPending } = useWriteContract();

  const { isLoading: isConfirming, isSuccess: isConfirmed } = 
    useWaitForTransactionReceipt({ hash });

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
            args: [CONTRACT_ADDRESSES.ETFv2, token.required * BigInt(2)], // 授权2倍以避免频繁授权
          });
          
          // 等待交易确认
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
      address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
      abi: ETFv2_ABI,
      functionName: 'invest',
      args: [[parseEther(amount)]], // 传递数组
    });
  };

  // ETH投资函数  
  const handleInvestWithETH = () => {
    if (!ethAmount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
      abi: ETFv2_ABI,
      functionName: 'investWithETH',
      args: [],
      value: parseEther(ethAmount),
    });
  };

  // 赎回函数
  const handleRedeem = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
      abi: ETFv2_ABI,
      functionName: 'redeem',
      args: [parseEther(amount)],
    });
  };

  // ETH赎回函数
  const handleRedeemWithETH = () => {
    if (!amount) return;
    
    writeContract({
      address: CONTRACT_ADDRESSES.ETFv2 as `0x${string}`,
      abi: ETFv2_ABI,
      functionName: 'redeemToETH',
      args: [parseEther(amount)],
    });
  };

  if (!isConnected) {
    return (
      <div className="text-center p-8">
        <p className="text-gray-600">请先连接钱包</p>
      </div>
    );
  }

  return (
    <div className="max-w-4xl mx-auto p-6">
      {/* ETF基本信息 */}
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
        <h2 className="text-2xl font-bold mb-4">
          {etfInfo?.[0]?.result as string} ({etfInfo?.[1]?.result as string})
        </h2>
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
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
            <p className="text-gray-600">我的ETH余额</p>
            <p className="text-lg font-semibold">
              通过钱包查看
            </p>
          </div>
        </div>
      </div>

      {/* 操作模式选择 */}
      <div className="bg-white rounded-lg shadow-lg p-6 mb-6">
        <div className="flex flex-wrap gap-2 mb-4">
          <button
            onClick={() => setMode('invest')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'invest' ? 'bg-blue-500 text-white' : 'bg-gray-200'
            }`}
          >
            代币投资
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
            onClick={() => setMode('redeem')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'redeem' ? 'bg-green-500 text-white' : 'bg-gray-200'
            }`}
          >
            代币赎回
          </button>
          <button
            onClick={() => setMode('redeemETH')}
            className={`px-4 py-2 rounded-lg ${
              mode === 'redeemETH' ? 'bg-green-500 text-white' : 'bg-gray-200'
            }`}
          >
            ETH赎回
          </button>
        </div>

        {/* 投资界面 */}
        {(mode === 'invest' || mode === 'redeem') && (
          <div className="space-y-4">
            <div>
              <label className="block text-sm font-medium text-gray-700 mb-2">
                {mode === 'invest' ? '投资数量' : '赎回数量'}
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
                <h3 className="font-medium">成分代币:</h3>
                {tokenDetails.map((token) => (
                  <div key={token.address} className="flex justify-between items-center p-3 bg-gray-50 rounded">
                    <span>{token.symbol}</span>
                    <div className="text-right">
                      <p className="text-sm">
                        余额: {formatEther(token.balance)}
                      </p>
                      <p className="text-sm">
                        {mode === 'invest' ? '需要' : '将得到'}: {formatEther(mode === 'invest' ? token.required : BigInt(0))}
                      </p>
                      {mode === 'invest' && (
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

            {mode === 'invest' && (
              <button
                onClick={handleBatchApprove}
                disabled={isApproving || !tokenDetails.some(t => t.allowance < t.required)}
                className="w-full bg-yellow-500 text-white py-2 px-4 rounded-lg disabled:bg-gray-300"
              >
                {isApproving ? '授权中...' : '批量授权'}
              </button>
            )}

            <button
              onClick={mode === 'invest' ? handleInvest : handleRedeem}
              disabled={isPending || isConfirming || !amount}
              className={`w-full py-2 px-4 rounded-lg text-white ${
                mode === 'invest' ? 'bg-blue-500' : 'bg-green-500'
              } disabled:bg-gray-300`}
            >
              {isPending || isConfirming 
                ? '处理中...' 
                : mode === 'invest' ? '投资' : '赎回'
              }
            </button>
          </div>
        )}

        {/* ETH投资界面 */}
        {(mode === 'investETH' || mode === 'redeemETH') && (
          <div className="space-y-4">
            {mode === 'investETH' ? (
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
            ) : (
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
            )}

            <div className="p-4 bg-yellow-50 rounded-lg">
              <p className="text-sm text-yellow-800">
                <strong>注意:</strong> ETH投资功能需要通过Uniswap V3进行代币交换。
                当前为简化版本，实际使用需要配置正确的交换路径。
              </p>
            </div>

            <button
              onClick={mode === 'investETH' ? handleInvestWithETH : handleRedeemWithETH}
              disabled={isPending || isConfirming || (mode === 'investETH' ? !ethAmount : !amount)}
              className={`w-full py-2 px-4 rounded-lg text-white ${
                mode === 'investETH' ? 'bg-blue-500' : 'bg-green-500'
              } disabled:bg-gray-300`}
            >
              {isPending || isConfirming 
                ? '处理中...' 
                : mode === 'investETH' ? '用ETH投资' : '赎回为ETH'
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

export default ETFv2Component;