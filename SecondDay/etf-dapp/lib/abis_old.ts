// ETFv1 合约 ABI
export const ETFv1_ABI = [
  // 查询函数
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
    name: "balanceOf",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "totalSupply",
    type: "function", 
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "getTokens",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address[]" }]
  },
  {
    name: "getInitTokenAmountPerShares",
    type: "function",
    stateMutability: "view", 
    inputs: [],
    outputs: [{ name: "", type: "uint256[]" }]
  },
  {
    name: "getInvestTokenAmounts",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "mintAmount", type: "uint256" }],
    outputs: [{ name: "tokenAmounts", type: "uint256[]" }]
  },
  {
    name: "getRedeemTokenAmounts", 
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "burnAmount", type: "uint256" }],
    outputs: [{ name: "tokenAmounts", type: "uint256[]" }]
  },
  
  // 投资和赎回函数
  {
    name: "invest",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "mintAmount", type: "uint256" }],
    outputs: []
  },
  {
    name: "redeem",
    type: "function", 
    stateMutability: "nonpayable",
    inputs: [{ name: "burnAmount", type: "uint256" }],
    outputs: []
  },
  
  // 事件
  {
    name: "Invest",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "mintAmount", type: "uint256", indexed: false },
      { name: "tokenAmounts", type: "uint256[]", indexed: false }
    ]
  },
  {
    name: "Redeem",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "burnAmount", type: "uint256", indexed: false },
      { name: "tokenAmounts", type: "uint256[]", indexed: false }
    ]
  }
] as const;

// ETFv2 合约 ABI (继承ETFv1并增加ETH投资功能)
export const ETFv2_ABI = [
  // 继承自ETFv1的所有函数
  ...ETFv1_ABI,
  
  // ETFv2新增函数
  {
    name: "investWithETH",
    type: "function",
    stateMutability: "payable",
    inputs: [
      { name: "swapPaths", type: "bytes[]" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: [{ name: "shares", type: "uint256" }]
  },
  {
    name: "redeemWithETH", 
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "burnAmount", type: "uint256" },
      { name: "swapPaths", type: "bytes[]" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: [{ name: "ethAmount", type: "uint256" }]
  },
  {
    name: "investWithToken",
    type: "function", 
    stateMutability: "nonpayable",
    inputs: [
      { name: "investToken", type: "address" },
      { name: "investAmount", type: "uint256" },
      { name: "swapPaths", type: "bytes[]" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: [{ name: "shares", type: "uint256" }]
  },
  {
    name: "redeemWithToken",
    type: "function",
    stateMutability: "nonpayable", 
    inputs: [
      { name: "burnAmount", type: "uint256" },
      { name: "targetToken", type: "address" },
      { name: "swapPaths", type: "bytes[]" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: [{ name: "tokenAmount", type: "uint256" }]
  },
  {
    name: "swapRouter",
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
  
  // ETFv2新增事件
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
    name: "RedeemWithETH",
    type: "event", 
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "shares", type: "uint256", indexed: false },
      { name: "ethAmount", type: "uint256", indexed: false }
    ]
  }
] as const;

// ETFv3Lite 合约 ABI (继承ETFv2并增加时间锁定功能)
export const ETFv3Lite_ABI = [
  // 继承自ETFv2的所有函数
  ...ETFv2_ABI,
  
  // ETFv3Lite新增函数
  {
    name: "lockDuration",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "lockEndTime",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "uint256" }]
  },
  {
    name: "investWithLock",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [{ name: "mintAmount", type: "uint256" }],
    outputs: []
  },
  {
    name: "investWithETHAndLock",
    type: "function",
    stateMutability: "payable",
    inputs: [
      { name: "swapPaths", type: "bytes[]" },
      { name: "deadline", type: "uint256" }
    ],
    outputs: [{ name: "shares", type: "uint256" }]
  },
  {
    name: "canRedeem",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "account", type: "address" }],
    outputs: [{ name: "", type: "bool" }]
  },
  
  // ETFv3Lite新增事件
  {
    name: "InvestWithLock",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "mintAmount", type: "uint256", indexed: false },
      { name: "lockEndTime", type: "uint256", indexed: false }
    ]
  },
  {
    name: "LockExtended",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "investor", type: "address", indexed: true },
      { name: "newLockEndTime", type: "uint256", indexed: false }
    ]
  }
] as const;

// ETFv4Lite 合约 ABI (集成Uniswap价格预言机功能)
export const ETFv4Lite_ABI = [
  // 继承自ETFv3Lite的所有函数
  ...ETFv3Lite_ABI,
  
  // ETFv4Lite新增函数
  {
    name: "priceOracle",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "address" }]
  },
  {
    name: "getTokenPrice",
    type: "function",
    stateMutability: "view",
    inputs: [{ name: "token", type: "address" }],
    outputs: [{ name: "price", type: "uint256" }]
  },
  {
    name: "getTotalValue",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "totalValue", type: "uint256" }]
  },
  {
    name: "getSharePrice",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "price", type: "uint256" }]
  },
  {
    name: "investWithPriceCheck",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "mintAmount", type: "uint256" },
      { name: "maxPricePerShare", type: "uint256" }
    ],
    outputs: []
  },
  {
    name: "redeemWithPriceCheck",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "burnAmount", type: "uint256" },
      { name: "minPricePerShare", type: "uint256" }
    ],
    outputs: []
  },
  {
    name: "emergencyPause",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    name: "emergencyUnpause",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [],
    outputs: []
  },
  {
    name: "paused",
    type: "function",
    stateMutability: "view",
    inputs: [],
    outputs: [{ name: "", type: "bool" }]
  },
  
  // ETFv4Lite新增事件
  {
    name: "PriceUpdated",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "token", type: "address", indexed: true },
      { name: "newPrice", type: "uint256", indexed: false },
      { name: "timestamp", type: "uint256", indexed: false }
    ]
  },
  {
    name: "EmergencyAction",
    type: "event",
    anonymous: false,
    inputs: [
      { name: "action", type: "string", indexed: false },
      { name: "timestamp", type: "uint256", indexed: false }
    ]
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
    name: "transferFrom",
    type: "function",
    stateMutability: "nonpayable",
    inputs: [
      { name: "from", type: "address" },
      { name: "to", type: "address" },
      { name: "amount", type: "uint256" }
    ],
    outputs: [{ name: "", type: "bool" }]
  }
] as const;