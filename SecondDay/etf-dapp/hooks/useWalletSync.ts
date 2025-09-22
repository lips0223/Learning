'use client';

import { useEffect } from 'react';
import { useAccount, useBalance, useChainId } from 'wagmi';
import { useWalletActions } from '../store/wallet';

export function useWalletSync() {
  const { address, isConnected } = useAccount();
  const chainId = useChainId();
  const { data: balance } = useBalance({
    address: address,
  });
  
  const {
    setWalletConnected,
    setWalletDisconnected,
    setBalance,
    setNetworkStatus
  } = useWalletActions();

  // 同步钱包连接状态
  useEffect(() => {
    if (isConnected && address && chainId) {
      setWalletConnected(address, chainId);
    } else {
      setWalletDisconnected();
    }
  }, [isConnected, address, chainId, setWalletConnected, setWalletDisconnected]);

  // 同步余额
  useEffect(() => {
    if (balance?.formatted) {
      setBalance(balance.formatted);
    }
  }, [balance, setBalance]);

  // 同步网络状态
  useEffect(() => {
    if (chainId) {
      const isCorrect = chainId === 11155111; // Sepolia
      const networkName = isCorrect ? 'Sepolia 测试网' : `网络 ID: ${chainId}`;
      setNetworkStatus(isCorrect, networkName);
    }
  }, [chainId, setNetworkStatus]);
}