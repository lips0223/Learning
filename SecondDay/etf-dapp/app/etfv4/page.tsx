import { Header } from "../../components/Header";
import ETFv4LiteComponent from "../../components/ETFv4LiteComponent";

export default function ETFv4() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              ETF v4 Lite - 价格预言机版ETF
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-2">
              集成Uniswap价格预言机，实时监控资产价值
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              支持价格保护、紧急暂停等高级风险管理功能
            </p>
          </div>
          
          <ETFv4LiteComponent />
        </div>
      </main>
    </div>
  );
}
