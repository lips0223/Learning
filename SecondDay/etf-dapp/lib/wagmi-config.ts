import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'ETF DApp',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || 'c4c8f6c3e6b2f9d3c1a7e5f4d2b9c8a6',
  chains: [sepolia],
  ssr: true, // If your dApp uses server side rendering (SSR)
});
