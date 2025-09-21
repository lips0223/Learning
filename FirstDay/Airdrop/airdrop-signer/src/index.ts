import * as dotenv from "dotenv";
dotenv.config();

import express, { Request, Response } from "express";
import { privateKeyToAccount } from "viem/accounts";
import {
  createWalletClient,
  encodePacked,
  keccak256,
  http,
  isAddress,
  toBytes,
} from "viem";
import { sepolia } from "viem/chains";

const app = express();
app.use(express.json());

// 从环境变量中加载私钥
const privateKey = process.env.PRIVATE_KEY;
if (!privateKey) {
  console.error("请在 .env 文件中设置 PRIVATE_KEY");
  process.exit(1);
}

// 创建钱包实例
const account = privateKeyToAccount(`0x${privateKey}`);
const client = createWalletClient({
  account,
  chain: sepolia,
  transport: http(),
});
console.log("wallet:", account.address);

// 全局 nonce（在生产环境中应持久化存储）
let currentNonce = 0;

// 定义请求和响应的类型
interface SignRequest {
  recipient: string;
}

interface SignResponse {
  amount: string;
  nonce: number;
  expireAt: number;
  signature: string;
}

// 签名请求处理函数
app.post(
  "/sign",
  async (
    req: Request<Record<string, any>, any, SignRequest>,
    res: Response<SignResponse | { error: string }>
  ): Promise<void> => {
    try {
      const { recipient } = req.body;

      // 获取空投数量
      const amount = getAmount(recipient);

      // 验证请求参数
      if (!isAddress(recipient)) {
        res.status(400).json({ error: "无效的以太坊地址" });
        return;
      }

      // 生成唯一的 nonce
      const nonce = ++currentNonce;

      // 生成过期时间
      const expireAt = Math.floor(Date.now() / 1000) + 24 * 60 * 60;

      // 构建消息哈希
      const messageHash = getMessageHash(recipient, amount, nonce, expireAt);

      // 签名消息
      const signature = await client.signMessage({
        message: { raw: toBytes(messageHash) },
      });

      // 返回签名和参数
      res.json({
        amount: amount,
        nonce: nonce,
        expireAt: expireAt,
        signature: signature,
      });
    } catch (error) {
      console.error("签名错误：", error);
      res.status(500).json({ error: "内部服务器错误" });
    }
  }
);

// 启动服务器
const PORT = process.env.PORT || 8080;
app.listen(PORT, () => {
  console.log(`服务器正在运行，监听端口 ${PORT}...`);
});

// 随机生成 1 到 10000 之间的金额
function getAmount(recipient: string): string {
  const min = 1;
  const max = 10000;
  const randomAmount = Math.floor(Math.random() * (max - min + 1)) + min;
  return randomAmount.toString();
}

// 构建消息哈希函数
function getMessageHash(
  recipient: string,
  amount: string,
  nonce: number,
  expireAt: number
): string {
  const types = ["address", "uint256", "uint256", "uint256"];
  const values = [recipient, amount, nonce, expireAt];

  const packedData = encodePacked(types, values);
  const messageHash = keccak256(packedData);

  return messageHash;
}
