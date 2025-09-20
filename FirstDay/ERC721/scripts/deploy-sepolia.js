const { ethers } = require("hardhat");

async function main() {
  console.log("🚀 开始在 Sepolia 测试网部署 LipsNft 合约...");
  
  // 检查网络
  const network = await ethers.provider.getNetwork();
  console.log("当前网络:", network.name, "Chain ID:", network.chainId.toString());
  
  if (network.chainId !== 11155111n) {
    console.log("❌ 错误: 当前不在 Sepolia 测试网");
    console.log("请使用: npx hardhat run scripts/deploy-sepolia.js --network sepolia");
    return;
  }

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  
  // 检查账户余额
  const balance = await ethers.provider.getBalance(deployer.address);
  console.log("账户余额:", ethers.formatEther(balance), "ETH");
  
  if (balance < ethers.parseEther("0.01")) {
    console.log("⚠️ 警告: 账户余额可能不足以支付 gas 费用");
    console.log("建议至少拥有 0.01 ETH 来部署合约");
  }

  // 估算部署成本
  const LipsNft = await ethers.getContractFactory("LipsNft");
  const deploymentData = LipsNft.getDeployTransaction();
  const estimatedGas = await ethers.provider.estimateGas(deploymentData);
  const gasPrice = await ethers.provider.getFeeData();
  
  console.log("预估 Gas:", estimatedGas.toString());
  console.log("Gas Price:", ethers.formatUnits(gasPrice.gasPrice || 0, "gwei"), "gwei");
  
  const estimatedCost = estimatedGas * (gasPrice.gasPrice || 0n);
  console.log("预估部署成本:", ethers.formatEther(estimatedCost), "ETH");
  
  // 部署合约
  console.log("\n📋 准备部署合约...");
  console.log("等待确认...");
  
  const lipsNft = await LipsNft.deploy();
  console.log("🔄 交易已提交，等待确认...");
  console.log("交易哈希:", lipsNft.deploymentTransaction().hash);
  
  // 等待部署完成
  await lipsNft.waitForDeployment();
  const contractAddress = await lipsNft.getAddress();
  
  console.log("\n✅ LipsNft 合约部署成功!");
  console.log("合约地址:", contractAddress);
  console.log("Sepolia Etherscan:", `https://sepolia.etherscan.io/address/${contractAddress}`);
  
  // 验证合约部署
  console.log("\n🔍 验证合约信息...");
  try {
    const name = await lipsNft.name();
    const symbol = await lipsNft.symbol();
    const maxSupply = await lipsNft.MAX_SUPPLY();
    const owner = await lipsNft.owner();
    
    console.log("合约名称:", name);
    console.log("合约符号:", symbol);
    console.log("最大供应量:", maxSupply.toString());
    console.log("合约拥有者:", owner);
  } catch (error) {
    console.log("⚠️ 验证合约信息时出错:", error.message);
  }
  
  // 保存部署信息
  const deploymentInfo = {
    contractName: "LipsNft",
    contractAddress: contractAddress,
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
    network: "sepolia",
    chainId: "11155111",
    transactionHash: lipsNft.deploymentTransaction().hash,
    etherscanUrl: `https://sepolia.etherscan.io/address/${contractAddress}`,
    estimatedGas: estimatedGas.toString(),
    gasPrice: gasPrice.gasPrice?.toString() || "0",
    deploymentCost: estimatedCost.toString()
  };
  
  const fs = require("fs");
  const path = require("path");
  
  // 确保 deployments 目录存在
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  // 保存部署信息
  const deploymentFile = path.join(deploymentsDir, "LipsNft-sepolia-deployment.json");
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n📝 部署信息已保存到:", deploymentFile);
  
  console.log("\n🎉 Sepolia 部署完成!");
  console.log("\n📖 后续操作:");
  console.log("1. 在 Etherscan 上验证合约源码:");
  console.log(`   npx hardhat verify --network sepolia ${contractAddress}`);
  console.log("\n2. 与合约交互:");
  console.log(`   npx hardhat run scripts/interact-sepolia.js --network sepolia`);
  console.log("\n3. 查看合约:");
  console.log(`   https://sepolia.etherscan.io/address/${contractAddress}`);
}

// 执行部署脚本
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Sepolia 部署失败:");
    console.error(error);
    process.exit(1);
  });
