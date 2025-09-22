'use client';

import { useState } from 'react';
import { useWalletInfo } from '../store/wallet';
import { TokenAirdropComponent } from './TokenAirdropComponent';
import { useWalletSync } from '../store/wallet-sync';

type TabType = 'airdrop' | 'etf' | 'governance';

export function DAppFeatures() {
  // 同步钱包状态
  useWalletSync();
  
  const { isConnected, isCorrectNetwork } = useWalletInfo();
  const [activeTab, setActiveTab] = useState<TabType>('airdrop');

  if (!isConnected || !isCorrectNetwork) {
    return (
      <div className="mt-12 text-center">
        <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-lg p-6 inline-block">
          <div className="flex items-center space-x-2">
            <svg className="w-5 h-5 text-yellow-600 dark:text-yellow-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-2.5L13.732 4c-.77-.833-1.964-.833-2.732 0L4.082 13.5c-.77.833.192 2.5 1.732 2.5z" />
            </svg>
            <span className="text-yellow-800 dark:text-yellow-300">
              {!isConnected ? '请先连接钱包以使用 DApp 功能' : '请切换到 Sepolia 测试网络'}
            </span>
          </div>
        </div>
      </div>
    );
  }

  const tabs = [
    { id: 'airdrop', label: '代币空投', icon: '🎁' },
    { id: 'etf', label: 'ETF 交易', icon: '📈' },
    { id: 'governance', label: '治理投票', icon: '🗳️' },
  ] as const;

  return (
    <div className="mt-12">
      {/* Tab 导航 */}
      <div className="border-b border-gray-200 dark:border-gray-700">
        <nav className="-mb-px flex space-x-8">
          {tabs.map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`py-4 px-1 border-b-2 font-medium text-sm whitespace-nowrap ${
                activeTab === tab.id
                  ? 'border-blue-500 text-blue-600 dark:text-blue-400'
                  : 'border-transparent text-gray-500 hover:text-gray-700 dark:text-gray-400 dark:hover:text-gray-300 hover:border-gray-300 dark:hover:border-gray-600'
              }`}
            >
              <span className="mr-2">{tab.icon}</span>
              {tab.label}
            </button>
          ))}
        </nav>
      </div>

      {/* Tab 内容 */}
      <div className="mt-8">
        {activeTab === 'airdrop' && (
          <div>
            <TokenAirdropComponent />
          </div>
        )}

        {activeTab === 'etf' && (
          <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-8 text-center">
            <div className="mb-4">
              <svg className="w-16 h-16 text-gray-400 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              ETF 交易功能
            </h3>
            <p className="text-gray-600 dark:text-gray-300 mb-6">
              即将推出多种 ETF 产品的去中心化交易功能
            </p>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div className="bg-white dark:bg-gray-700 rounded-md p-4">
                <h4 className="font-medium text-gray-900 dark:text-white mb-2">ETF v1</h4>
                <p className="text-sm text-gray-600 dark:text-gray-300">基础 ETF 交易</p>
              </div>
              <div className="bg-white dark:bg-gray-700 rounded-md p-4">
                <h4 className="font-medium text-gray-900 dark:text-white mb-2">ETF v2</h4>
                <p className="text-sm text-gray-600 dark:text-gray-300">增强 ETF 功能</p>
              </div>
              <div className="bg-white dark:bg-gray-700 rounded-md p-4">
                <h4 className="font-medium text-gray-900 dark:text-white mb-2">ETF v3</h4>
                <p className="text-sm text-gray-600 dark:text-gray-300">高级 ETF 策略</p>
              </div>
              <div className="bg-white dark:bg-gray-700 rounded-md p-4">
                <h4 className="font-medium text-gray-900 dark:text-white mb-2">ETF Upgradeable</h4>
                <p className="text-sm text-gray-600 dark:text-gray-300">可升级 ETF 合约</p>
              </div>
            </div>
          </div>
        )}

        {activeTab === 'governance' && (
          <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-8 text-center">
            <div className="mb-4">
              <svg className="w-16 h-16 text-gray-400 mx-auto" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1} d="M9 5H7a2 2 0 00-2 2v10a2 2 0 002 2h8a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2m-6 9l2 2 4-4" />
              </svg>
            </div>
            <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-2">
              治理投票
            </h3>
            <p className="text-gray-600 dark:text-gray-300 mb-6">
              参与平台治理，对重要提案进行投票
            </p>
            <div className="bg-yellow-50 dark:bg-yellow-900/20 rounded-md p-4">
              <p className="text-sm text-yellow-800 dark:text-yellow-300">
                🚧 治理功能正在开发中，敬请期待！
              </p>
            </div>
          </div>
        )}
      </div>
    </div>
  );
}