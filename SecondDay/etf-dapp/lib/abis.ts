// 合约ABI定义文件

// ERC20 标准代币 ABI
export const ERC20_ABI = [
  {
    name: "name",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "string" }]
  },
  {
    name: "symbol", 
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "string" }]
  },
  {
    name: "decimals",
    type: "function", 
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint8" }]
  },
  {
    name: "totalSupply",
    type: "function",
    stateMutability: "view", 
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "transfer",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "allowance",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "owner", type: "address" },
      { name: "spender", type: "address" }
    ],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "approve",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "spender", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "transferFrom",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "Transfer",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "from", type: "address", indexed: true },
      { name: "to", type: "address", indexed: true },
      { name: "value", type: "uint256", indexed: false }
    ]
  },
  {
    name: "Approval",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "owner", type: "address", indexed: true },
      { name: "spender", type: "address", indexed: true },
      { name: "value", type: "uint256", indexed: false }
    ]
  }
] as const;

// ETFv1 合约 ABI
export const ETFv1_ABI = [
  ...ERC20_ABI,
  {
    name: "tokenAddresses",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "uint256" }],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "tokenWeights",
    type: "function", 
    stateMutability: "view",
    inputs: [{ name: "", type: "uint256" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "invest",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "_amounts", type: "uint256[]" }],
    outputs: []
  },
  {
    name: "redeem",
    type: "function",
    stateMutability: "nonpayable", 
    inputs: [{ name: "_shares", type: "uint256" }],
    outputs: []
  },
  {
    name: "getTokenAddresses",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }]
  },
  {
    name: "getTokenWeights",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256[]" }]
  },
  {
    name: "calculateShares",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_amounts", type: "uint256[]" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "calculateTokenAmounts",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_shares", type: "uint256" }],
    outputs: [{ name: "", type: "uint256[]" }]
  },
  {
    name: "Invest",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "shares", type: "uint256", indexed: false },
      { name: "amounts", type: "uint256[]", indexed: false }
    ]
  },
  {
    name: "Redeem",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "shares", type: "uint256", indexed: false },
      { name: "amounts", type: "uint256[]", indexed: false }
    ]
  }
] as const;

// ETFv2 合约 ABI
export const ETFv2_ABI = [
  ...ETFv1_ABI,
  {
    name: "uniswapRouter",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "weth",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "investWithETH",
    type: "function",
    stateMutability: "payable",
    inputs: [],
    outputs: []
  },
  {
    name: "redeemToETH",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "_shares", type: "uint256" }],
    outputs: []
  },
  {
    name: "getETHInvestmentQuote",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_ethAmount", type: "uint256" }],
    outputs: [
      { name: "tokenAmounts", type: "uint256[]" },
      { name: "shares", type: "uint256" }
    ]
  },
  {
    name: "InvestWithETH",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "ethAmount", type: "uint256", indexed: false },
      { name: "shares", type: "uint256", indexed: false }
    ]
  },
  {
    name: "RedeemToETH",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "shares", type: "uint256", indexed: false },
      { name: "ethAmount", type: "uint256", indexed: false }
    ]
  }
] as const;

// ETFv3Lite 合约 ABI
export const ETFv3Lite_ABI = [
  ...ETFv2_ABI,
  {
    name: "lockDuration",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "investmentLocks",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "setLockDuration",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "_lockDuration", type: "uint256" }],
    outputs: []
  },
  {
    name: "getInvestmentLockTime",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_investor", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "isRedeemAllowed",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_investor", type: "address" }],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "LockDurationUpdated",
    type: "event",
    anonymous: false,
    inputs: [{ name: "newDuration", type: "uint256", indexed: false }]
  }
] as const;

// ETFv4Lite 合约 ABI
export const ETFv4Lite_ABI = [
  ...ETFv3Lite_ABI,
  {
    name: "priceOracle",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "maxPriceDeviation",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "paused",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "owner",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "setPriceOracle",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "_oracle", type: "address" }],
    outputs: []
  },
  {
    name: "setMaxPriceDeviation",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "_deviation", type: "uint256" }],
    outputs: []
  },
  {
    name: "pause",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    name: "unpause",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    name: "getTokenPrice",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_token", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "validatePrices",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "_amounts", type: "uint256[]" }],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "PriceOracleUpdated",
    type: "event",
    anonymous: false,
    inputs: [{ name: "newOracle", type: "address", indexed: true }]
  },
  {
    name: "MaxPriceDeviationUpdated",
    type: "event",
    anonymous: false,
    inputs: [{ name: "newDeviation", type: "uint256", indexed: false }]
  },
  {
    name: "Paused",
    type: "event",
    anonymous: false,
    inputs: [{ name: "account", type: "address", indexed: false }]
  },
  {
    name: "Unpaused",
    type: "event",
    anonymous: false,
    inputs: [{ name: "account", type: "address", indexed: false }]
  }
] as const;

// ETFUUPSUpgradeable 合约 ABI (可升级代理合约)
export const ETFUUPSUpgradeable_ABI = [
  // 继承自ETFv4Lite的所有函数
  ...ETFv4Lite_ABI,
  
  // UUPS升级函数
  {
    name: "upgradeTo",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "newImplementation", type: "address" }],
    outputs: []
  },
  {
    name: "upgradeToAndCall",
    type: "function",
    stateMutability: "payable",
    inputs: [
      { name: "newImplementation", type: "address" },
      { name: "data", type: "bytes" }
    ],
    outputs: []
  },
  {
    name: "implementation",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "proxiableUUID",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bytes32" }]
  },
  
  // 升级事件
  {
    name: "Upgraded",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "implementation", type: "address", indexed: true }
    ]
  }
] as const;

// ETFProtocolToken ABI (治理代币)
export const ETFProtocolToken_ABI = [
  // ERC20基础函数
  ...ERC20_ABI,
  
  // 治理功能
  {
    name: "mint",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: []
  },
  {
    name: "burn",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "amount", type: "uint256" }],
    outputs: []
  },
  {
    name: "burnFrom",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "account", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: []
  },
  {
    name: "hasRole",
    type: "function",
    stateMutability: "view",
    inputs: [
      { name: "role", type: "bytes32" },
      { name: "account", type: "address" }
    ],
    outputs: [{ name: "", type: "bool" }]
  },
  {
    name: "grantRole",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "role", type: "bytes32" },
      { name: "account", type: "address" }
    ],
    outputs: []
  },
  {
    name: "revokeRole",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "role", type: "bytes32" },
      { name: "account", type: "address" }
    ],
    outputs: []
  }
] as const;

// ETFProxyFactory ABI (代理工厂)
export const ETFProxyFactory_ABI = [
  {
    name: "createETFProxy",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "implementation", type: "address" },
      { name: "initData", type: "bytes" }
    ],
    outputs: [{ name: "proxy", type: "address" }]
  },
  {
    name: "getETFProxies",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }]
  },
  {
    name: "getETFProxyCount",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "isETFProxy",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "proxy", type: "address" }],
    outputs: [{ name: "", type: "bool" }]
  },
  
  // 工厂事件
  {
    name: "ETFProxyCreated",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "proxy", type: "address", indexed: true },
      { name: "implementation", type: "address", indexed: true },
      { name: "creator", type: "address", indexed: true }
    ]
  }
] as const;