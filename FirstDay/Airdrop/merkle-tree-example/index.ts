import { StandardMerkleTree } from "@openzeppelin/merkle-tree";

type ValueTuple = [number, string, number]; // [index, address, amount]

// 示例数据 包含用户索引 地址 和 可领取的代币数量

const values: ValueTuple[] = [
  [0, "0x1956b2c4C511FDDd9443f50b36C4597D10cD9985", 1000000],
  [1, "0xd2020857fC3334590E85b048b99f837178d7512a", 2000000],
  [2, "0x312820cd273068cb0f9DA97b39fc91B6603bcf48", 5000000],
  [3, "0x3C903A5Ea5Ebf8d2236cEe40E16678806276F246", 3000000],
  [4, "0x1A3Fb58f9aeB50641476d2016783031C4f325C2d", 5500000],
  [255, "0x7fD9b416c8605204b2074617c962b222A152191F", 3500000],
  [500, "0xC654c886aBa508Af1b89c931775C81dD11ba7c3f", 1200000],
  [1250, "0xC30DDa4cB4B1e2d8b2EfeB1f5114cBd413611262", 6800000],
];
//StandardMerkleTree.of(values, ["uint256", "address", "uint256"]);
// 生成 Merkle 树 
const tree = StandardMerkleTree.of(values, ["uint256", "address", "uint256"]);

console.log("Merkle Root:", tree.root);

const output = document.getElementById("output");

if (output) {
  output.innerText = `Merkle Root: ${tree.root}\n\n`;

  for (const [i, v] of tree.entries()) {
    const proof = tree.getProof(i);
    output.innerText += `Value: ${JSON.stringify(v)}\nProof: ${JSON.stringify(
      proof
    )}\n\n`;
  }
}
