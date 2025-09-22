import { Header } from "../components/Header";

export default function Home() {
  return (
    <div className="min-h-screen bg-white dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-4xl mx-auto">
          {/* Hero Section */}
          <div className="text-center mb-12">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              Welcome to ETF DApp
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
              A decentralized platform for ETF token management and airdrops
            </p>
          </div>

          {/* Feature Cards */}
          <div className="grid md:grid-cols-2 gap-8 mb-12">
            <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">
                Token Airdrop
              </h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Claim tokens using cryptographic signatures from our secure backend service.
              </p>
              <div className="bg-blue-50 dark:bg-blue-900/20 rounded-md p-4">
                <p className="text-sm text-blue-800 dark:text-blue-300">
                  Connect your wallet to start claiming tokens
                </p>
              </div>
            </div>

            <div className="bg-gray-50 dark:bg-gray-800 rounded-lg p-6">
              <h3 className="text-xl font-semibold text-gray-900 dark:text-white mb-3">
                MockToken Management
              </h3>
              <p className="text-gray-600 dark:text-gray-300 mb-4">
                Mint, burn, and manage various test tokens including WBTC, USDC, USDT, LINK, and UNI.
              </p>
              <div className="bg-green-50 dark:bg-green-900/20 rounded-md p-4">
                <p className="text-sm text-green-800 dark:text-green-300">
                  Interact with deployed MockToken contracts
                </p>
              </div>
            </div>
          </div>

          {/* Status Section */}
          <div className="text-center">
            <div className="inline-flex items-center px-4 py-2 rounded-full bg-green-100 dark:bg-green-900/20 text-green-800 dark:text-green-300">
              <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
              Connected to Sepolia Testnet
            </div>
          </div>
        </div>
      </main>
    </div>
  );
}
