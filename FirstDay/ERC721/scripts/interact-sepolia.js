const { ethers } = require("hardhat");

async function main() {
  console.log("🔗 连接到 Sepolia 测试网上的 LipsNft 合约...");
  
  // 检查网络
  const network = await ethers.provider.getNetwork();
  console.log("当前网络:", network.name, "Chain ID:", network.chainId.toString());
  
  if (network.chainId !== 11155111n) {
    console.log("❌ 错误: 当前不在 Sepolia 测试网");
    console.log("请使用: npx hardhat run scripts/interact-sepolia.js --network sepolia");
    return;
  }

  // 从部署文件中读取合约地址
  const fs = require("fs");
  const path = require("path");
  
  const deploymentFile = path.join(__dirname, "../deployments/LipsNft-sepolia-deployment.json");
  
  if (!fs.existsSync(deploymentFile)) {
    console.log("❌ 找不到 Sepolia 部署文件");
    console.log("请先运行: npx hardhat run scripts/deploy-sepolia.js --network sepolia");
    return;
  }
  
  const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  const contractAddress = deploymentInfo.contractAddress;
  
  console.log("合约地址:", contractAddress);
  console.log("Etherscan:", deploymentInfo.etherscanUrl);
  
  // 获取合约实例
  const LipsNft = await ethers.getContractFactory("LipsNft");
  const lipsNft = LipsNft.attach(contractAddress);
  
  // 获取当前账户
  const [account] = await ethers.getSigners();
  console.log("当前账户:", account.address);
  
  // 检查账户余额
  const balance = await ethers.provider.getBalance(account.address);
  console.log("账户余额:", ethers.formatEther(balance), "ETH");
  
  console.log("\n=== 合约状态查询 ===");
  
  try {
    // 查询基本信息
    const name = await lipsNft.name();
    const symbol = await lipsNft.symbol();
    const maxSupply = await lipsNft.MAX_SUPPLY();
    const totalSupply = await lipsNft.totalSupply();
    const owner = await lipsNft.owner();
    
    console.log("合约名称:", name);
    console.log("合约符号:", symbol);
    console.log("最大供应量:", maxSupply.toString());
    console.log("当前供应量:", totalSupply.toString());
    console.log("合约拥有者:", owner);
    
    // 查询当前账户持有的 NFT
    const userBalance = await lipsNft.balanceOf(account.address);
    console.log("你持有的 NFT 数量:", userBalance.toString());
    
    if (userBalance > 0) {
      console.log("你持有的 NFT Token IDs:");
      for (let i = 0; i < userBalance; i++) {
        const tokenId = await lipsNft.tokenOfOwnerByIndex(account.address, i);
        console.log(`  - Token ID: ${tokenId.toString()}`);
      }
    }
    
  } catch (error) {
    console.log("❌ 查询合约状态失败:", error.message);
    return;
  }
  
  console.log("\n=== 交互选项 ===");
  console.log("如果你是合约拥有者，可以执行以下操作：");
  
  // 检查是否是拥有者
  const owner = await lipsNft.owner();
  const isOwner = owner.toLowerCase() === account.address.toLowerCase();
  
  if (isOwner) {
    console.log("✅ 你是合约拥有者，可以执行管理操作");
    
    // 示例：设置基础 URI
    console.log("\n1. 设置基础 URI...");
    try {
      const baseURI = "https://gateway.pinata.cloud/ipfs/your-metadata-hash/";
      console.log("设置基础 URI 为:", baseURI);
      
      // 估算 gas
      const gasEstimate = await lipsNft.setBaseURI.estimateGas(baseURI);
      console.log("预估 Gas:", gasEstimate.toString());
      
      // 执行交易 (注释掉以避免意外执行)
      // const tx1 = await lipsNft.setBaseURI(baseURI);
      // console.log("交易哈希:", tx1.hash);
      // await tx1.wait();
      // console.log("✅ 基础 URI 设置成功");
      
      console.log("💡 取消注释上面的代码来实际执行");
      
    } catch (error) {
      console.log("❌ 设置基础 URI 失败:", error.message);
    }
    
    // 示例：铸造 NFT
    console.log("\n2. 铸造 NFT...");
    try {
      const mintTo = account.address; // 铸造给自己
      console.log("铸造 NFT 给:", mintTo);
      
      // 估算 gas
      const gasEstimate = await lipsNft.safeMint.estimateGas(mintTo);
      console.log("预估 Gas:", gasEstimate.toString());
      
      // 执行交易 (注释掉以避免意外执行)
      // const tx2 = await lipsNft.safeMint(mintTo);
      // console.log("交易哈希:", tx2.hash);
      // await tx2.wait();
      // console.log("✅ NFT 铸造成功");
      
      console.log("💡 取消注释上面的代码来实际执行");
      
    } catch (error) {
      console.log("❌ 铸造 NFT 失败:", error.message);
    }
    
  } else {
    console.log("ℹ️ 你不是合约拥有者，只能查询信息");
    console.log("合约拥有者:", owner);
  }
  
  console.log("\n🎉 Sepolia 交互完成!");
  console.log("🔗 在 Etherscan 上查看合约:", deploymentInfo.etherscanUrl);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("\n❌ Sepolia 交互失败:");
    console.error(error);
    process.exit(1);
  });
