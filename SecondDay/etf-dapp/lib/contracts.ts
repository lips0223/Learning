export const CONTRACTS = {
  // TokenAirDrop 合约
  TOKEN_AIRDROP: {
    address: process.env.NEXT_PUBLIC_TOKEN_AIRDROP_CONTRACT as `0x${string}` || '0x53850d0eb69feB0F2616e2A89AC9eFBE4A441569',
    abi: [
      "function claimTokens(address token, uint256 amount, uint256 nonce, uint256 expireAt, bytes signature) external",
      "function getUserNonce(address user) external view returns (uint256)",
      "function getUserClaimed(address user, address token) external view returns (uint256)",
      "function nonceUsed(address user, uint256 nonce) external view returns (bool)",
      "function signer() external view returns (address)",
      "function owner() external view returns (address)",
      "event TokensClaimed(address indexed user, address indexed token, uint256 amount, uint256 nonce)"
    ]
  },
  
  // MockToken 合约配置
  MOCK_TOKENS: {
    WBTC: {
      address: process.env.NEXT_PUBLIC_WBTC_CONTRACT as `0x${string}`,
      symbol: 'nWBTC',
      name: 'New Mock Wrapped Bitcoin',
      decimals: 8
    },
    USDC: {
      address: process.env.NEXT_PUBLIC_USDC_CONTRACT as `0x${string}`,
      symbol: 'nUSDC',
      name: 'New Mock USD Coin',
      decimals: 6
    },
    USDT: {
      address: process.env.NEXT_PUBLIC_USDT_CONTRACT as `0x${string}`,
      symbol: 'nUSDT',
      name: 'New Mock Tether USD',
      decimals: 6
    },
    LINK: {
      address: process.env.NEXT_PUBLIC_LINK_CONTRACT as `0x${string}`,
      symbol: 'nLINK',
      name: 'New Mock Chainlink Token',
      decimals: 18
    },
    UNI: {
      address: process.env.NEXT_PUBLIC_UNI_CONTRACT as `0x${string}`,
      symbol: 'nWETH',
      name: 'New Mock Wrapped Ether',
      decimals: 18
    }
  },
  
  // MockToken ABI
  MOCK_TOKEN_ABI: [
    "function mint(address to, uint256 amount) external",
    "function burn(uint256 amount) external",
    "function burnFrom(address from, uint256 amount) external",
    "function balanceOf(address account) external view returns (uint256)",
    "function totalSupply() external view returns (uint256)",
    "function transfer(address to, uint256 amount) external returns (bool)",
    "function transferFrom(address from, address to, uint256 amount) external returns (bool)",
    "function approve(address spender, uint256 amount) external returns (bool)",
    "function allowance(address owner, address spender) external view returns (uint256)",
    "function name() external view returns (string)",
    "function symbol() external view returns (string)",
    "function decimals() external view returns (uint8)",
    "event Transfer(address indexed from, address indexed to, uint256 value)",
    "event Approval(address indexed owner, address indexed spender, uint256 value)",
    "event Mint(address indexed to, uint256 amount)",
    "event Burn(address indexed from, uint256 amount)"
  ]
} as const;

// 网络配置
export const SEPOLIA_CHAIN = {
  id: 11155111,
  name: 'Sepolia',
  nativeCurrency: {
    decimals: 18,
    name: 'Ethereum',
    symbol: 'ETH',
  },
  rpcUrls: {
    public: { http: [process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL || 'https://ethereum-sepolia-rpc.publicnode.com'] },
    default: { http: [process.env.NEXT_PUBLIC_SEPOLIA_RPC_URL || 'https://ethereum-sepolia-rpc.publicnode.com'] },
  },
  blockExplorers: {
    default: { name: 'Etherscan', url: 'https://sepolia.etherscan.io' },
  },
  testnet: true,
} as const;

// API 配置
export const API_CONFIG = {
  BASE_URL: process.env.NEXT_PUBLIC_API_BASE_URL || 'https://learning-hir12yip3-xiaolis-projects-1babd2b2.vercel.app',
  ENDPOINTS: {
    HEALTH: '/health',
    GENERATE_SIGNATURE: '/api/signatures/generate',
    VERIFY_SIGNATURE: '/api/signatures/verify',
    SIGNER_INFO: '/api/signatures/signer'
  }
} as const;
