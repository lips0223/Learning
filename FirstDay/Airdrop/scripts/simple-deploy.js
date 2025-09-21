const hre = require("hardhat");

async function main() {
  console.log("开始部署 MultiTransfer 合约...");

  // 获取部署者账户
  const [deployer] = await hre.ethers.getSigners();
  console.log("部署者地址:", deployer.address);

  // 部署合约 - 需要一个代币地址作为参数
  // 这里使用一个示例地址，您需要替换为实际的 ERC20 代币地址
  const tokenAddress = "0x1234567890123456789012345678901234567890"; // 替换为实际的代币地址
  
  const MultiTransfer = await hre.ethers.getContractFactory("MultiTransfer");
  const multiTransfer = await MultiTransfer.deploy(tokenAddress);
  
  await multiTransfer.deployed();
  
  console.log("MultiTransfer 合约部署成功!");
  console.log("合约地址:", multiTransfer.address);
  console.log("配置的代币地址:", tokenAddress);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
