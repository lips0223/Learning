'use client';

import { useWalletInfo, useWalletStatus } from '../store/wallet';
import { useWalletSync } from '../hooks/useWalletSync';
import { ConnectButton } from '@rainbow-me/rainbowkit';
import { AlertTriangle, CheckCircle, Loader2 } from 'lucide-react';

export function WalletStatus() {
  // 同步钱包状态
  useWalletSync();
  
  const { isConnected, shortAddress, formattedBalance, isCorrectNetwork, networkName } = useWalletInfo();
  const { isConnecting, isLoading, error } = useWalletStatus();

  if (!isConnected) {
    return (
      <div className="text-center py-12">
        <div className="max-w-md mx-auto">
          <div className="mb-6">
            <div className="mx-auto w-16 h-16 bg-gray-100 dark:bg-gray-800 rounded-full flex items-center justify-center mb-4">
              <AlertTriangle className="w-8 h-8 text-gray-400" />
            </div>
            <h3 className="text-lg font-semibold text-gray-900 dark:text-white mb-2">
              请连接钱包
            </h3>
            <p className="text-gray-600 dark:text-gray-300">
              连接你的钱包以开始使用 ETF DApp 的所有功能
            </p>
          </div>
        </div>
      </div>
    );
  }

  return (
    <div className="space-y-6">
      {/* 钱包信息卡片 */}
      <div className="bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 p-6">
        <div className="flex items-center justify-between mb-4">
          <h3 className="text-lg font-semibold text-gray-900 dark:text-white">
            钱包信息
          </h3>
          <div className="flex items-center space-x-2">
            {isCorrectNetwork ? (
              <CheckCircle className="w-5 h-5 text-green-500" />
            ) : (
              <AlertTriangle className="w-5 h-5 text-yellow-500" />
            )}
            <span className={`text-sm font-medium ${
              isCorrectNetwork 
                ? 'text-green-600 dark:text-green-400' 
                : 'text-yellow-600 dark:text-yellow-400'
            }`}>
              {networkName}
            </span>
          </div>
        </div>

        <div className="space-y-3">
          <div className="flex justify-between items-center">
            <span className="text-sm text-gray-600 dark:text-gray-400">地址:</span>
            <span className="text-sm font-mono text-gray-900 dark:text-white">
              {shortAddress}
            </span>
          </div>

          {formattedBalance && (
            <div className="flex justify-between items-center">
              <span className="text-sm text-gray-600 dark:text-gray-400">余额:</span>
              <span className="text-sm font-semibold text-gray-900 dark:text-white">
                {formattedBalance}
              </span>
            </div>
          )}
        </div>

        {!isCorrectNetwork && (
          <div className="mt-4 p-3 bg-yellow-50 dark:bg-yellow-900/20 rounded-md">
            <p className="text-sm text-yellow-800 dark:text-yellow-300">
              请切换到 Sepolia 测试网以使用完整功能
            </p>
          </div>
        )}
      </div>

      {/* 错误提示 */}
      {error && (
        <div className="bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-md p-4">
          <div className="flex">
            <AlertTriangle className="w-5 h-5 text-red-400 flex-shrink-0" />
            <div className="ml-3">
              <p className="text-sm text-red-800 dark:text-red-300">
                {error}
              </p>
            </div>
          </div>
        </div>
      )}

      {/* 加载状态 */}
      {(isConnecting || isLoading) && (
        <div className="flex items-center justify-center py-4">
          <Loader2 className="w-5 h-5 animate-spin text-blue-500 mr-2" />
          <span className="text-sm text-gray-600 dark:text-gray-300">
            {isConnecting ? '连接中...' : '加载中...'}
          </span>
        </div>
      )}
    </div>
  );
}