const { ethers } = require("hardhat");

async function main() {
  // 从部署文件中读取合约地址
  const fs = require("fs");
  const path = require("path");
  
  const deploymentFile = path.join(__dirname, "../deployments/LipsNft-deployment.json");
  
  if (!fs.existsSync(deploymentFile)) {
    console.log("❌ 找不到部署文件，请先运行部署脚本");
    return;
  }
  
  const deploymentInfo = JSON.parse(fs.readFileSync(deploymentFile, "utf8"));
  const contractAddress = deploymentInfo.contractAddress;
  
  console.log("连接到已部署的合约:", contractAddress);
  
  // 获取合约实例
  const LipsNft = await ethers.getContractFactory("LipsNft");
  const lipsNft = LipsNft.attach(contractAddress);
  
  // 获取部署者账户
  const [deployer] = await ethers.getSigners();
  console.log("当前账户:", deployer.address);
  
  // 示例操作
  console.log("\n=== 合约交互示例 ===");
  
  // 1. 设置基础 URI
  console.log("1. 设置基础 URI...");
  const baseURI = "https://ipfs.io/ipfs/your-metadata-hash/";
  try {
    const tx1 = await lipsNft.setBaseURI(baseURI);
    await tx1.wait();
    console.log("✅ 基础 URI 设置成功");
  } catch (error) {
    console.log("⚠️ 设置基础 URI 失败:", error.message);
  }
  
  // 2. 铸造第一个 NFT
  console.log("\n2. 铸造 NFT...");
  try {
    const tx2 = await lipsNft.safeMint(deployer.address);
    await tx2.wait();
    console.log("✅ NFT 铸造成功");
    
    // 查询总供应量
    const totalSupply = await lipsNft.totalSupply();
    console.log("当前总供应量:", totalSupply.toString());
    
    // 查询用户持有的 NFT
    const balance = await lipsNft.balanceOf(deployer.address);
    console.log("用户持有数量:", balance.toString());
    
    if (balance > 0) {
      const tokenId = await lipsNft.tokenOfOwnerByIndex(deployer.address, 0);
      console.log("第一个 NFT 的 Token ID:", tokenId.toString());
    }
    
  } catch (error) {
    console.log("⚠️ 铸造 NFT 失败:", error.message);
  }
  
  // 3. 查询合约状态
  console.log("\n3. 查询合约状态...");
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
  
  console.log("\n🎉 交互完成!");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error("❌ 交互失败:");
    console.error(error);
    process.exit(1);
  });
