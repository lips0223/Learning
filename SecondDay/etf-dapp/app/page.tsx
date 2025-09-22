import { Header } from "../components/Header";
import { WalletStatus } from "../components/WalletStatus";
import { DAppFeatures } from "../components/DAppFeatures";

export default function Home() {
  return (
    <div className="min-h-screen bg-white dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-4xl mx-auto">
          {/* 主标题区域 */}
          <div className="text-center mb-12">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              欢迎来到 ETF DApp
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-8">
              去中心化的 ETF 代币管理和空投平台
            </p>
          </div>

          {/* 钱包状态 */}
          <WalletStatus />

          {/* 功能组件（仅在钱包连接且网络正确时显示） */}
          <DAppFeatures />
        </div>
      </main>
    </div>
  );
}