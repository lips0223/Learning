import { Header } from "../../components/Header";
import ETFv2Component from "../../components/ETFv2Component";

export default function ETFv2() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              ETF v2 - 增强版ETF
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-2">
              支持ETH直接投资和任意代币交换
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              通过Uniswap V3实现灵活的投资和赎回方式
            </p>
          </div>
          
          <ETFv2Component />
        </div>
      </main>
    </div>
  );
}
