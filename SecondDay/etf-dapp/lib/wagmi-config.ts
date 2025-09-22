import { getDefaultConfig } from '@rainbow-me/rainbowkit';
import { sepolia } from 'wagmi/chains';

export const config = getDefaultConfig({
  appName: 'ETF DApp',
  projectId: process.env.NEXT_PUBLIC_WALLET_CONNECT_PROJECT_ID || '6818ce72410b489488fe53b9fc9c636e',
  chains: [sepolia],
  ssr: true, // If your dApp uses server side rendering (SSR)
});
