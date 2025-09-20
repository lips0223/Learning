const { ethers } = require("hardhat");

async function main() {
  console.log("开始部署 LipsNft 合约...");

  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("部署账户:", deployer.address);
  console.log("账户余额:", ethers.formatEther(await ethers.provider.getBalance(deployer.address)), "ETH");

  // 获取合约工厂
  const LipsNft = await ethers.getContractFactory("LipsNft");
  
  // 部署合约
  console.log("正在部署合约...");
  const lipsNft = await LipsNft.deploy();
  
  // 等待部署完成
  await lipsNft.waitForDeployment();
  const contractAddress = await lipsNft.getAddress();
  
  console.log("✅ LipsNft 合约部署成功!");
  console.log("合约地址:", contractAddress);
  console.log("交易哈希:", lipsNft.deploymentTransaction().hash);
  
  // 验证合约部署
  console.log("\n验证合约信息...");
  const name = await lipsNft.name();
  const symbol = await lipsNft.symbol();
  const maxSupply = await lipsNft.MAX_SUPPLY();
  const owner = await lipsNft.owner();
  
  console.log("合约名称:", name);
  console.log("合约符号:", symbol);
  console.log("最大供应量:", maxSupply.toString());
  console.log("合约拥有者:", owner);
  
  // 保存部署信息到文件
  const deploymentInfo = {
    contractName: "LipsNft",
    contractAddress: contractAddress,
    deployer: deployer.address,
    deploymentTime: new Date().toISOString(),
    network: (await ethers.provider.getNetwork()).name,
    chainId: (await ethers.provider.getNetwork()).chainId.toString(),
    transactionHash: lipsNft.deploymentTransaction().hash,
    contractInfo: {
      name: name,
      symbol: symbol,
      maxSupply: maxSupply.toString(),
      owner: owner
    }
  };
  
  const fs = require("fs");
  const path = require("path");
  
  // 确保 deployments 目录存在
  const deploymentsDir = path.join(__dirname, "../deployments");
  if (!fs.existsSync(deploymentsDir)) {
    fs.mkdirSync(deploymentsDir, { recursive: true });
  }
  
  // 保存部署信息
  const deploymentFile = path.join(deploymentsDir, "LipsNft-deployment.json");
  fs.writeFileSync(deploymentFile, JSON.stringify(deploymentInfo, null, 2));
  
  console.log("\n📝 部署信息已保存到:", deploymentFile);
  
  console.log("\n🎉 部署完成!");
  console.log("你现在可以:");
  console.log(`1. 设置基础 URI: await contract.setBaseURI("https://your-metadata-url/")`);
  console.log(`2. 铸造 NFT: await contract.safeMint("${deployer.address}")`);
}

// 执行部署脚本
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ 部署失败:");
    console.error(error);
    process.exit(1);
  });
