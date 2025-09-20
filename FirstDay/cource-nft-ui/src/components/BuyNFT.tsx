import { usdtAbi } from "../abis/usdt";
import { courceNftAbi } from "../abis/courceNFT";
import { useReadContract, useWriteContract } from "wagmi";
import { zeroAddress } from "viem";
import { useEffect, useState } from "react";
import { usdtAddress, courceNftAddress } from "./Constants";

export const BuyNFT = ({
  address,
  price,
}: {
  address: string;
  price: bigint;
}) => {
  // 钱包USDT余额逻辑
  const [balanceString, setBalanceString] = useState<string>("0");
  const [hasEnoughBalance, setEnoughBalance] = useState<boolean>(false);

  const { data: balanceData } = useReadContract({
    abi: usdtAbi,
    address: usdtAddress,
    functionName: "balanceOf",
    args: [address],
  });

  useEffect(() => {
    if (balanceData && typeof balanceData === "bigint") {
      setBalanceString((balanceData / BigInt(1000000)).toString());
      if (balanceData >= price) {
        setEnoughBalance(true);
      } else {
        setEnoughBalance(false);
      }
    }
  }, [balanceData, price]);

  // 推荐人逻辑
  const [hasReferrer, setHasReferrer] = useState<boolean>(false);
  const [referrer, setReferrer] = useState<string>(zeroAddress);

  const { refetch } = useReadContract({
    abi: courceNftAbi,
    address: courceNftAddress,
    functionName: "referrerCommissionRatio",
    args: [referrer],
  });

  const checkReferrer = async () => {
    if (referrer) {
      const { data } = await refetch();
      if (data && typeof data === "number" && data > 0) {
        alert("推荐人有效");
      } else {
        alert("无效的推荐人地址");
      }
    } else {
      alert("请填写推荐人地址");
    }
  };

  const { data: hash, writeContractAsync: buy, error } = useWriteContract();
  const handleBuy = () => {
    if (buy) {
      buy({
        abi: courceNftAbi,
        address: courceNftAddress,
        functionName: "buy",
        args: [referrer],
      });
    } else {
      console.error("buy函数不可用");
    }
  };

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault(); // 阻止默认表单提交行为
    handleBuy();
  };

  return (
    <div>
      <h3>Step2：购买NFT</h3>
      <p>您的钱包余额：{balanceString} USDT</p>
      {hasEnoughBalance ? (
        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: "10px" }}>
            <label>
              <input
                type="checkbox"
                checked={hasReferrer}
                onChange={(e) => setHasReferrer(e.target.checked)}
              />
              是否有推荐人
            </label>
          </div>
          {hasReferrer && (
            <div style={{ marginBottom: "10px" }}>
              <label>
                推荐人地址：
                <input
                  type="text"
                  value={referrer}
                  onChange={(e) => setReferrer(e.target.value)}
                  style={{ width: "350px" }}
                />
              </label>
              <button
                type="button"
                className="button"
                onClick={checkReferrer}
                style={{ marginLeft: "10px" }}
              >
                检查推荐人
              </button>
            </div>
          )}
          <button className="button" type="submit">
            提交购买
          </button>
          <p>
            购买交易哈希：
            <a
              href={`https://arbiscan.io/tx/${hash}`}
              target="_blank"
              rel="noopener noreferrer"
            >
              {hash}
            </a>
          </p>
        </form>
      ) : (
        <div>
          <p>
            余额不足，
            <a
              href="https://www.okx.com/zh-hans/web3/dex-swap/bridge?inputChain=1&inputCurrency=0xdac17f958d2ee523a2206206994597c13d831ec7&outputChain=42161&outputCurrency=0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9"
              target="_blank"
              rel="noopener noreferrer"
            >
              去跨链转或兑换
            </a>
          </p>
        </div>
      )}
      {error && <p style={{ color: "red" }}>Error: {error.message}</p>}
    </div>
  );
};
