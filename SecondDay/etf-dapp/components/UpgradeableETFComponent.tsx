"use client";

import { useState } from 'react';
import { useAccount, useReadContract, useWriteContract, useWaitForTransactionReceipt } from 'wagmi';
import { parseEther, formatEther } from 'viem';
import { ETFUUPSUpgradeable_ABI, ERC20_ABI } from '@/lib/abis';
import { CONTRACT_ADDRESSES } from '@/lib/contracts';

export default function UpgradeableETFComponent() {
  const { address, isConnected } = useAccount();
  const { writeContract, data: hash, error, isPending } = useWriteContract();
  const { isLoading: isConfirming, isSuccess: isConfirmed } = useWaitForTransactionReceipt({ hash });

  // 状态管理
  const [amounts, setAmounts] = useState<string[]>(['', '', '']);
  const [shares, setShares] = useState<string>('');
  const [newImplementation, setNewImplementation] = useState<string>('');
  const [upgradeData, setUpgradeData] = useState<string>('');
  const [activeTab, setActiveTab] = useState<'invest' | 'redeem' | 'upgrade' | 'admin'>('invest');

  // 读取ETF代币信息
  const { data: etfName } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'name',
  });

  const { data: etfSymbol } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'symbol',
  });

  const { data: etfBalance } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: { enabled: !!address }
  });

  const { data: totalSupply } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'totalSupply',
  });

  // 读取代币地址和权重
  const { data: tokenAddresses } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'getTokenAddresses',
  });

  const { data: tokenWeights } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'getTokenWeights',
  });

  // 读取升级相关信息
  const { data: currentImplementation } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'implementation',
  });

  const { data: proxiableUUID } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'proxiableUUID',
  });

  const { data: owner } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'owner',
  });

  const { data: paused } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'paused',
  });

  const { data: lockDuration } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'lockDuration',
  });

  // 读取代币余额
  const { data: token0Balance } = useReadContract({
    address: tokenAddresses?.[0] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: { enabled: !!address && !!tokenAddresses?.[0] }
  });

  const { data: token1Balance } = useReadContract({
    address: tokenAddresses?.[1] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: { enabled: !!address && !!tokenAddresses?.[1] }
  });

  const { data: token2Balance } = useReadContract({
    address: tokenAddresses?.[2] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'balanceOf',
    args: [address],
    query: { enabled: !!address && !!tokenAddresses?.[2] }
  });

  // 代币名称
  const { data: token0Name } = useReadContract({
    address: tokenAddresses?.[0] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'symbol',
    query: { enabled: !!tokenAddresses?.[0] }
  });

  const { data: token1Name } = useReadContract({
    address: tokenAddresses?.[1] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'symbol',
    query: { enabled: !!tokenAddresses?.[1] }
  });

  const { data: token2Name } = useReadContract({
    address: tokenAddresses?.[2] as `0x${string}`,
    abi: ERC20_ABI,
    functionName: 'symbol',
    query: { enabled: !!tokenAddresses?.[2] }
  });

  // 读取用户投资锁定状态
  const { data: investmentLock } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'getInvestmentLockTime',
    args: [address],
    query: { enabled: !!address }
  });

  const { data: redeemAllowed } = useReadContract({
    address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
    abi: ETFUUPSUpgradeable_ABI,
    functionName: 'isRedeemAllowed',
    args: [address],
    query: { enabled: !!address }
  });

  // 投资函数
  const handleInvest = async () => {
    if (!amounts.every(amount => amount && parseFloat(amount) > 0)) {
      alert('请输入有效的投资金额');
      return;
    }

    try {
      const tokenAmounts = amounts.map(amount => parseEther(amount));
      
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'invest',
        args: [tokenAmounts],
      });
    } catch (error) {
      console.error('投资失败:', error);
    }
  };

  // ETH投资函数
  const handleInvestWithETH = async () => {
    if (!amounts[0] || parseFloat(amounts[0]) <= 0) {
      alert('请输入有效的ETH数量');
      return;
    }

    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'investWithETH',
        value: parseEther(amounts[0]),
      });
    } catch (error) {
      console.error('ETH投资失败:', error);
    }
  };

  // 赎回函数
  const handleRedeem = async () => {
    if (!shares || parseFloat(shares) <= 0) {
      alert('请输入有效的份额数量');
      return;
    }

    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'redeem',
        args: [parseEther(shares)],
      });
    } catch (error) {
      console.error('赎回失败:', error);
    }
  };

  // ETH赎回函数
  const handleRedeemToETH = async () => {
    if (!shares || parseFloat(shares) <= 0) {
      alert('请输入有效的份额数量');
      return;
    }

    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'redeemToETH',
        args: [parseEther(shares)],
      });
    } catch (error) {
      console.error('ETH赎回失败:', error);
    }
  };

  // 升级函数
  const handleUpgrade = async () => {
    if (!newImplementation) {
      alert('请输入新的实现合约地址');
      return;
    }

    try {
      if (upgradeData && upgradeData.trim() !== '') {
        // 使用upgradeToAndCall
        writeContract({
          address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
          abi: ETFUUPSUpgradeable_ABI,
          functionName: 'upgradeToAndCall',
          args: [newImplementation as `0x${string}`, upgradeData as `0x${string}`],
        });
      } else {
        // 使用upgradeTo
        writeContract({
          address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
          abi: ETFUUPSUpgradeable_ABI,
          functionName: 'upgradeTo',
          args: [newImplementation as `0x${string}`],
        });
      }
    } catch (error) {
      console.error('升级失败:', error);
    }
  };

  // 暂停/恢复函数
  const handlePause = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'pause',
      });
    } catch (error) {
      console.error('暂停失败:', error);
    }
  };

  const handleUnpause = async () => {
    try {
      writeContract({
        address: CONTRACT_ADDRESSES.ETFUUPSUpgradeable as `0x${string}`,
        abi: ETFUUPSUpgradeable_ABI,
        functionName: 'unpause',
      });
    } catch (error) {
      console.error('恢复失败:', error);
    }
  };

  // 检查是否为管理员
  const isOwner = address && owner && address.toLowerCase() === owner.toLowerCase();

  if (!isConnected) {
    return (
      <div className="max-w-4xl mx-auto p-6">
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-4">
          <p className="text-yellow-800">请先连接钱包</p>
        </div>
      </div>
    );
  }

  return (
    <div className="max-w-6xl mx-auto p-6 space-y-6">
      {/* ETF信息卡片 */}
      <div className="bg-white rounded-lg shadow-lg p-6 border border-purple-100">
        <h2 className="text-2xl font-bold text-purple-800 mb-4">
          🔄 {etfName || 'ETF'} ({etfSymbol || 'ETF'}) - 可升级版本
        </h2>
        
        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div className="bg-purple-50 p-4 rounded-lg">
            <h3 className="font-semibold text-purple-700">我的份额</h3>
            <p className="text-2xl font-bold text-purple-900">
              {etfBalance ? parseFloat(formatEther(etfBalance)).toFixed(4) : '0.0000'}
            </p>
          </div>
          
          <div className="bg-blue-50 p-4 rounded-lg">
            <h3 className="font-semibold text-blue-700">总供应量</h3>
            <p className="text-2xl font-bold text-blue-900">
              {totalSupply ? parseFloat(formatEther(totalSupply)).toFixed(4) : '0.0000'}
            </p>
          </div>
          
          <div className="bg-green-50 p-4 rounded-lg">
            <h3 className="font-semibold text-green-700">锁定期</h3>
            <p className="text-2xl font-bold text-green-900">
              {lockDuration ? `${Number(lockDuration) / 86400}天` : '未设置'}
            </p>
          </div>
        </div>

        {/* 系统状态 */}
        <div className="mt-4 grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className={`p-3 rounded-lg ${paused ? 'bg-red-50' : 'bg-green-50'}`}>
            <h4 className={`font-semibold ${paused ? 'text-red-700' : 'text-green-700'}`}>
              系统状态: {paused ? '已暂停' : '正常运行'}
            </h4>
          </div>
          
          {investmentLock && Number(investmentLock) > 0 && (
            <div className={`p-3 rounded-lg ${redeemAllowed ? 'bg-green-50' : 'bg-yellow-50'}`}>
              <h4 className={`font-semibold ${redeemAllowed ? 'text-green-700' : 'text-yellow-700'}`}>
                赎回状态: {redeemAllowed ? '可赎回' : `锁定中 (${new Date(Number(investmentLock) * 1000).toLocaleString()})`}
              </h4>
            </div>
          )}
        </div>
      </div>

      {/* 标签导航 */}
      <div className="bg-white rounded-lg shadow-lg border border-purple-100">
        <div className="border-b border-gray-200">
          <nav className="flex space-x-8">
            {[
              { id: 'invest', label: '💰 投资', color: 'green' },
              { id: 'redeem', label: '💸 赎回', color: 'red' },
              { id: 'upgrade', label: '⬆️ 升级', color: 'blue' },
              { id: 'admin', label: '⚙️ 管理', color: 'purple' }
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setActiveTab(tab.id as 'invest' | 'redeem' | 'upgrade' | 'admin')}
                className={`py-4 px-1 border-b-2 font-medium text-sm transition-colors ${
                  activeTab === tab.id
                    ? `border-${tab.color}-500 text-${tab.color}-600`
                    : 'border-transparent text-gray-500 hover:text-gray-700 hover:border-gray-300'
                }`}
              >
                {tab.label}
              </button>
            ))}
          </nav>
        </div>

        <div className="p-6">
          {/* 投资面板 */}
          {activeTab === 'invest' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold text-green-700">💰 投资ETF</h3>
              
              {/* 代币投资 */}
              <div className="bg-green-50 p-4 rounded-lg">
                <h4 className="font-semibold text-green-700 mb-3">代币投资</h4>
                {tokenAddresses && tokenWeights && (
                  <div className="space-y-3">
                    {tokenAddresses.map((tokenAddr: string, index: number) => (
                      <div key={index} className="flex items-center space-x-4">
                        <span className="w-20 text-sm font-medium">
                          {[token0Name, token1Name, token2Name][index] || `Token${index + 1}`}:
                        </span>
                        <span className="w-16 text-xs text-gray-600">
                          权重: {tokenWeights[index] ? Number(tokenWeights[index]).toString() : '0'}%
                        </span>
                        <input
                          type="number"
                          placeholder="数量"
                          value={amounts[index] || ''}
                          onChange={(e) => {
                            const newAmounts = [...amounts];
                            newAmounts[index] = e.target.value;
                            setAmounts(newAmounts);
                          }}
                          className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                        />
                        <span className="w-20 text-xs text-gray-600">
                          余额: {
                            index === 0 ? (token0Balance ? parseFloat(formatEther(token0Balance)).toFixed(4) : '0') :
                            index === 1 ? (token1Balance ? parseFloat(formatEther(token1Balance)).toFixed(4) : '0') :
                            (token2Balance ? parseFloat(formatEther(token2Balance)).toFixed(4) : '0')
                          }
                        </span>
                      </div>
                    ))}
                  </div>
                )}
                <button
                  onClick={handleInvest}
                  disabled={isPending || isConfirming || paused}
                  className="mt-4 w-full bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                >
                  {isPending ? '确认中...' : isConfirming ? '处理中...' : '投资'}
                </button>
              </div>

              {/* ETH投资 */}
              <div className="bg-blue-50 p-4 rounded-lg">
                <h4 className="font-semibold text-blue-700 mb-3">ETH投资</h4>
                <div className="flex items-center space-x-4">
                  <input
                    type="number"
                    placeholder="ETH数量"
                    value={amounts[0] || ''}
                    onChange={(e) => {
                      const newAmounts = [...amounts];
                      newAmounts[0] = e.target.value;
                      setAmounts(newAmounts);
                    }}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <button
                    onClick={handleInvestWithETH}
                    disabled={isPending || isConfirming || paused}
                    className="bg-blue-600 hover:bg-blue-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                  >
                    {isPending ? '确认中...' : isConfirming ? '处理中...' : 'ETH投资'}
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* 赎回面板 */}
          {activeTab === 'redeem' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold text-red-700">💸 赎回ETF</h3>
              
              <div className="bg-red-50 p-4 rounded-lg">
                <h4 className="font-semibold text-red-700 mb-3">赎回为代币</h4>
                <div className="flex items-center space-x-4">
                  <input
                    type="number"
                    placeholder="份额数量"
                    value={shares}
                    onChange={(e) => setShares(e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <button
                    onClick={handleRedeem}
                    disabled={isPending || isConfirming || !redeemAllowed || paused}
                    className="bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                  >
                    {isPending ? '确认中...' : isConfirming ? '处理中...' : '赎回'}
                  </button>
                </div>
                {!redeemAllowed && (
                  <p className="mt-2 text-sm text-red-600">
                    ⚠️ 投资仍在锁定期内，无法赎回
                  </p>
                )}
              </div>

              <div className="bg-yellow-50 p-4 rounded-lg">
                <h4 className="font-semibold text-yellow-700 mb-3">赎回为ETH</h4>
                <div className="flex items-center space-x-4">
                  <input
                    type="number"
                    placeholder="份额数量"
                    value={shares}
                    onChange={(e) => setShares(e.target.value)}
                    className="flex-1 px-3 py-2 border border-gray-300 rounded-md"
                  />
                  <button
                    onClick={handleRedeemToETH}
                    disabled={isPending || isConfirming || !redeemAllowed || paused}
                    className="bg-yellow-600 hover:bg-yellow-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                  >
                    {isPending ? '确认中...' : isConfirming ? '处理中...' : '赎回为ETH'}
                  </button>
                </div>
              </div>
            </div>
          )}

          {/* 升级面板 */}
          {activeTab === 'upgrade' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold text-blue-700">⬆️ 合约升级</h3>
              
              {/* 当前实现信息 */}
              <div className="bg-blue-50 p-4 rounded-lg">
                <h4 className="font-semibold text-blue-700 mb-3">当前实现信息</h4>
                <div className="space-y-2 text-sm">
                  <div>
                    <span className="font-medium">实现地址:</span>
                    <span className="ml-2 font-mono text-xs break-all">
                      {currentImplementation || '加载中...'}
                    </span>
                  </div>
                  <div>
                    <span className="font-medium">代理UUID:</span>
                    <span className="ml-2 font-mono text-xs break-all">
                      {proxiableUUID || '加载中...'}
                    </span>
                  </div>
                  <div>
                    <span className="font-medium">合约所有者:</span>
                    <span className="ml-2 font-mono text-xs break-all">
                      {owner || '加载中...'}
                    </span>
                  </div>
                </div>
              </div>

              {/* 升级操作 */}
              {isOwner ? (
                <div className="bg-indigo-50 p-4 rounded-lg">
                  <h4 className="font-semibold text-indigo-700 mb-3">执行升级</h4>
                  <div className="space-y-3">
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        新实现合约地址:
                      </label>
                      <input
                        type="text"
                        placeholder="0x..."
                        value={newImplementation}
                        onChange={(e) => setNewImplementation(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md font-mono text-sm"
                      />
                    </div>
                    <div>
                      <label className="block text-sm font-medium text-gray-700 mb-1">
                        初始化数据 (可选):
                      </label>
                      <input
                        type="text"
                        placeholder="0x (留空使用upgradeTo)"
                        value={upgradeData}
                        onChange={(e) => setUpgradeData(e.target.value)}
                        className="w-full px-3 py-2 border border-gray-300 rounded-md font-mono text-sm"
                      />
                    </div>
                    <button
                      onClick={handleUpgrade}
                      disabled={isPending || isConfirming || !newImplementation}
                      className="w-full bg-indigo-600 hover:bg-indigo-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                    >
                      {isPending ? '确认中...' : isConfirming ? '处理中...' : '执行升级'}
                    </button>
                  </div>
                </div>
              ) : (
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-gray-600">只有合约所有者可以执行升级操作</p>
                </div>
              )}
            </div>
          )}

          {/* 管理面板 */}
          {activeTab === 'admin' && (
            <div className="space-y-6">
              <h3 className="text-lg font-semibold text-purple-700">⚙️ 系统管理</h3>
              
              {isOwner ? (
                <div className="space-y-4">
                  {/* 暂停/恢复控制 */}
                  <div className="bg-purple-50 p-4 rounded-lg">
                    <h4 className="font-semibold text-purple-700 mb-3">紧急控制</h4>
                    <div className="flex space-x-3">
                      <button
                        onClick={handlePause}
                        disabled={isPending || isConfirming || paused}
                        className="bg-red-600 hover:bg-red-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                      >
                        {isPending ? '确认中...' : isConfirming ? '处理中...' : '暂停系统'}
                      </button>
                      <button
                        onClick={handleUnpause}
                        disabled={isPending || isConfirming || !paused}
                        className="bg-green-600 hover:bg-green-700 disabled:bg-gray-400 text-white font-semibold py-2 px-4 rounded transition-colors"
                      >
                        {isPending ? '确认中...' : isConfirming ? '处理中...' : '恢复系统'}
                      </button>
                    </div>
                  </div>

                  {/* 系统信息 */}
                  <div className="bg-gray-50 p-4 rounded-lg">
                    <h4 className="font-semibold text-gray-700 mb-3">系统信息</h4>
                    <div className="space-y-2 text-sm">
                      <div>管理员地址: <span className="font-mono">{address}</span></div>
                      <div>系统状态: <span className={paused ? 'text-red-600' : 'text-green-600'}>
                        {paused ? '已暂停' : '正常运行'}
                      </span></div>
                      <div>锁定期: {lockDuration ? `${Number(lockDuration) / 86400}天` : '未设置'}</div>
                    </div>
                  </div>
                </div>
              ) : (
                <div className="bg-gray-50 p-4 rounded-lg">
                  <p className="text-gray-600">只有合约所有者可以访问管理功能</p>
                </div>
              )}
            </div>
          )}
        </div>
      </div>

      {/* 交易状态 */}
      {(isPending || isConfirming || isConfirmed) && (
        <div className="bg-white rounded-lg shadow-lg p-6 border border-blue-100">
          <h3 className="text-lg font-semibold text-blue-700 mb-3">交易状态</h3>
          {isPending && <p className="text-blue-600">⏳ 等待用户确认...</p>}
          {isConfirming && <p className="text-yellow-600">⏳ 交易确认中...</p>}
          {isConfirmed && <p className="text-green-600">✅ 交易成功！</p>}
          {hash && (
            <p className="text-sm text-gray-600 mt-2">
              交易哈希: <span className="font-mono">{hash}</span>
            </p>
          )}
        </div>
      )}

      {/* 错误信息 */}
      {error && (
        <div className="bg-red-50 border border-red-200 rounded-lg p-4">
          <p className="text-red-800">❌ 错误: {error.message}</p>
        </div>
      )}
    </div>
  );
}