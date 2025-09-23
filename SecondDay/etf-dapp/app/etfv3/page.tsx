import { Header } from "../../components/Header";
import ETFv3LiteComponent from "../../components/ETFv3LiteComponent";

export default function ETFv3() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
              ETF v3 Lite - 时间锁定版ETF
            </h1>
            <p className="text-xl text-gray-600 dark:text-gray-300 mb-2">
              增加时间锁定机制，锁定期间无法赎回
            </p>
            <p className="text-sm text-gray-500 dark:text-gray-400">
              支持锁定投资以获得额外收益和风险管理
            </p>
          </div>
          
          <ETFv3LiteComponent />
        </div>
      </main>
    </div>
  );
}
