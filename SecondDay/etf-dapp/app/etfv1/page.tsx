import { Header } from "../../components/Header";
import { ETFv1Component } from "../../components/ETFv1Component";

export default function ETFv1() {
  return (
    <div className="min-h-screen bg-white dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              ETF v1
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-2">
              基础ETF投资产品
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              支持多代币投资组合的铸造和赎回功能
            </p>
          </div>
          
          <ETFv1Component />
        </div>
      </main>
    </div>
  );
}
