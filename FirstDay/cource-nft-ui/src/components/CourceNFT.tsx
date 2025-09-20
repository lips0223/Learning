import { courceNftAbi } from "../abis/courceNFT";
import { useAccount, useReadContract } from "wagmi";
import { useState, useEffect } from "react";
import { Approve } from "./Approve";
import { BuyNFT } from "./BuyNFT";
import { Consume } from "./Consume";
import { Referral } from "./Referral";
import { courceNftAddress } from "./Constants";

export const CourceNFT = () => {
  const { address, isConnected } = useAccount();
  const [price, setPrice] = useState<string>("");

  const { data, refetch } = useReadContract({
    address: courceNftAddress,
    abi: courceNftAbi,
    functionName: "price",
  });

  // 使用 useEffect 设置一个定时器，每隔 10 秒触发一次 refetch
  useEffect(() => {
    const interval = setInterval(() => {
      refetch(); // 手动触发重新读取合约数据
    }, 10000); // 10 秒

    // 清理定时器，避免内存泄漏
    return () => clearInterval(interval);
  }, [refetch]);

  // 使用 useEffect 监听 data 的变化，并更新 price 状态
  useEffect(() => {
    if (data) {
      setPrice(data.toString()); // 更新 price 状态
    }
  }, [data]); // 当 data 更新时触发此 useEffect

  return (
    <div>
      <h2>
        课程介绍：
        <a
          href="https://zhuanlan.zhihu.com/p/4762714791"
          target="_blank"
          rel="noopener noreferrer"
        >
          https://zhuanlan.zhihu.com/p/2662403696
        </a>
      </h2>
      <h2>
        合约地址：
        <a
          href="https://arbiscan.io/address/0xff86a1f61a68496a3b1111696808459098c49b29#code"
          target="_blank"
          rel="noopener noreferrer"
        >
          0xFF86A1f61a68496A3B1111696808459098C49b29
        </a>
      </h2>
      <h2>
        当前价格：
        {Number(
          (typeof price === "bigint" ? price : BigInt(price)) / BigInt(1000000)
        )}{" "}
        USDT
      </h2>
      <hr />
      <Referral address={address || ""} />
      <hr />
      <h2>购买和核销流程</h2>
      {isConnected ? (
        <div>
          <hr />
          <Approve address={address || ""} price={BigInt(price)} />
          <hr />
          <BuyNFT address={address || ""} price={BigInt(price)} />
          <hr />
          <Consume address={address || ""} />
        </div>
      ) : (
        <h2 className="highlight">请先Connect Wallet</h2>
      )}
      <h2 className="highlight">
        <p>
          以上操作嫌麻烦，想用最懒的购买方式，直接加钢哥微信（keegan704）代操作
        </p>
      </h2>
    </div>
  );
};
