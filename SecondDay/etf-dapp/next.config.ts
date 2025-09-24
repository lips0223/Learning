import type { NextConfig } from "next";

const nextConfig: NextConfig = {
  transpilePackages: ['@rainbow-me/rainbowkit'],
  output: 'standalone',
  trailingSlash: false,
  webpack: (config, { isServer }) => {
    if (!isServer) {
      // 只为浏览器环境配置必要的 fallback
      config.resolve.fallback = {
        ...config.resolve.fallback,
        fs: false,
        net: false,
        tls: false,
        crypto: false,
        // 忽略 React Native 和 Node.js 特定模块
        'react-native': false,
        '@react-native-async-storage/async-storage': false,
        'pino-pretty': false,
        'encoding': false,
      };
      
      // 忽略这些模块的导入错误
      config.externals = config.externals || [];
      config.externals.push({
        'pino-pretty': 'commonjs pino-pretty',
        'encoding': 'commonjs encoding',
      });
    }
    
    return config;
  },
};

export default nextConfig;
