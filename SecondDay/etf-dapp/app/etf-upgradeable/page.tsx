import { Header } from "../../components/Header";
import UpgradeableETFComponent from "../../components/UpgradeableETFComponent";

export default function ETFUpgradeable() {
  return (
    <div className="min-h-screen bg-gray-50 dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-6xl mx-auto">
          <div className="text-center mb-8">
            <h1 className="text-4xl font-bold text-purple-900 dark:text-purple-100 mb-4">
              🔄 ETF 可升级版本
            </h1>
            <div className="text-lg text-purple-700 dark:text-purple-300 space-y-2">
              <p>⚡ 支持UUPS代理模式的可升级ETF合约</p>
              <p>🔒 继承价格预言机、时间锁定等所有高级功能</p>
              <p>🔧 管理员可无缝升级合约实现而不影响用户资产</p>
              <p>⚙️ 支持紧急暂停/恢复、升级管理等治理功能</p>
            </div>
          </div>
          
          <UpgradeableETFComponent />
        </div>
      </main>
    </div>
  );
}
