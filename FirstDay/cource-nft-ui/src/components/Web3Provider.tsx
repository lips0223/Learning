import "@rainbow-me/rainbowkit/styles.css";
import {
  getDefaultConfig,
  RainbowKitProvider,
  ConnectButton,
} from "@rainbow-me/rainbowkit";
import { WagmiProvider } from "wagmi";
import { arbitrum } from "wagmi/chains";
import { QueryClientProvider, QueryClient } from "@tanstack/react-query";
import { CourceNFT } from "./CourceNFT";

const config = getDefaultConfig({
  appName: "CourceNFT",
  projectId: "5389107099f8225b488f2fc473658a62",
  chains: [arbitrum],
  ssr: true, // If your dApp uses server side rendering (SSR)
});

const queryClient = new QueryClient();

export const Web3Provider = () => {
  return (
    <WagmiProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <RainbowKitProvider>
          <ConnectButton />
          <p />
          <CourceNFT />
        </RainbowKitProvider>
      </QueryClientProvider>
    </WagmiProvider>
  );
};
