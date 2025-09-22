import { Header } from "../../components/Header";

export default function ETFv2() {
  return (
    <div className="min-h-screen bg-white dark:bg-gray-900">
      <Header />
      <main className="container mx-auto px-4 sm:px-6 lg:px-8 py-8">
        <div className="max-w-4xl mx-auto text-center">
          <h1 className="text-4xl font-bold text-gray-900 dark:text-white mb-4">
            ETF v2
          </h1>
          <p className="text-xl text-gray-600 dark:text-gray-300">
            ETF version 2 functionality will be implemented here.
          </p>
        </div>
      </main>
    </div>
  );
}
