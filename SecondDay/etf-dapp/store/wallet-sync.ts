'use client';

import { useEffect } from 'react';
import { useAccount, useBalance, useChainId } from 'wagmi';
import { useWalletStore } from './wallet';
import { formatEther } from 'viem';

/**
 * 同步 wagmi 状态到 zustand store 的 hook
 */
export const useWalletSync = () => {
  const { address, isConnected, isConnecting } = useAccount();
  const chainId = useChainId();
  const { data: balance } = useBalance({ address });
  
  const { 
    setWalletConnected, 
    setWalletDisconnected, 
    setBalance, 
    setConnecting,
    setNetworkStatus 
  } = useWalletStore();

  // 同步连接状态
  useEffect(() => {
    if (isConnected && address && chainId) {
      setWalletConnected(address, chainId);
    } else {
      setWalletDisconnected();
    }
  }, [isConnected, address, chainId, setWalletConnected, setWalletDisconnected]);

  // 同步余额
  useEffect(() => {
    if (balance) {
      const formattedBalance = formatEther(balance.value);
      setBalance(formattedBalance);
    }
  }, [balance, setBalance]);

  // 同步连接中状态
  useEffect(() => {
    setConnecting(isConnecting);
  }, [isConnecting, setConnecting]);

  // 同步网络状态
  useEffect(() => {
    if (chainId) {
      const isCorrect = chainId === 11155111; // Sepolia
      const networkName = isCorrect ? 'Sepolia' : '未知网络';
      setNetworkStatus(isCorrect, networkName);
    }
  }, [chainId, setNetworkStatus]);

  return {
    address,
    isConnected,
    isConnecting,
    chainId,
    balance: balance?.value,
    isCorrectNetwork: chainId === 11155111,
  };
};