import { create } from 'zustand';
import { subscribeWithSelector } from 'zustand/middleware';

export interface WalletState {
  // 钱包连接状态
  isConnected: boolean;
  address: string | null;
  chainId: number | null;
  balance: string | null;
  
  // 网络状态
  isCorrectNetwork: boolean;
  networkName: string | null;
  
  // 加载状态
  isConnecting: boolean;
  isLoading: boolean;
  
  // 错误状态
  error: string | null;
  
  // Actions
  setWalletConnected: (address: string, chainId: number) => void;
  setWalletDisconnected: () => void;
  setBalance: (balance: string) => void;
  setNetworkStatus: (isCorrect: boolean, networkName: string) => void;
  setConnecting: (isConnecting: boolean) => void;
  setLoading: (isLoading: boolean) => void;
  setError: (error: string | null) => void;
  clearError: () => void;
}

export const useWalletStore = create<WalletState>()(
  subscribeWithSelector((set) => ({
    // 初始状态
    isConnected: false,
    address: null,
    chainId: null,
    balance: null,
    isCorrectNetwork: false,
    networkName: null,
    isConnecting: false,
    isLoading: false,
    error: null,

    // Actions
    setWalletConnected: (address: string, chainId: number) => {
      set({
        isConnected: true,
        address,
        chainId,
        isConnecting: false,
        error: null,
        isCorrectNetwork: chainId === 11155111, // Sepolia
        networkName: chainId === 11155111 ? 'Sepolia' : '未知网络'
      });
    },

    setWalletDisconnected: () => {
      set({
        isConnected: false,
        address: null,
        chainId: null,
        balance: null,
        isCorrectNetwork: false,
        networkName: null,
        isConnecting: false,
        error: null
      });
    },

    setBalance: (balance: string) => {
      set({ balance });
    },

    setNetworkStatus: (isCorrect: boolean, networkName: string) => {
      set({
        isCorrectNetwork: isCorrect,
        networkName
      });
    },

    setConnecting: (isConnecting: boolean) => {
      set({ isConnecting });
    },

    setLoading: (isLoading: boolean) => {
      set({ isLoading });
    },

    setError: (error: string | null) => {
      set({ error });
    },

    clearError: () => {
      set({ error: null });
    }
  }))
);

// 派生状态选择器
export const useWalletInfo = () => {
  const store = useWalletStore();
  return {
    isConnected: store.isConnected,
    address: store.address,
    shortAddress: store.address ? `${store.address.slice(0, 6)}...${store.address.slice(-4)}` : null,
    chainId: store.chainId,
    balance: store.balance,
    formattedBalance: store.balance ? `${parseFloat(store.balance).toFixed(4)} ETH` : null,
    isCorrectNetwork: store.isCorrectNetwork,
    networkName: store.networkName
  };
};

export const useWalletActions = () => {
  const store = useWalletStore();
  return {
    setWalletConnected: store.setWalletConnected,
    setWalletDisconnected: store.setWalletDisconnected,
    setBalance: store.setBalance,
    setNetworkStatus: store.setNetworkStatus,
    setConnecting: store.setConnecting,
    setLoading: store.setLoading,
    setError: store.setError,
    clearError: store.clearError
  };
};

export const useWalletStatus = () => {
  const store = useWalletStore();
  return {
    isConnecting: store.isConnecting,
    isLoading: store.isLoading,
    error: store.error
  };
};