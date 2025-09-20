import { courceNftAbi } from "../abis/courceNFT";
import { useReadContract, useWriteContract } from "wagmi";
import { useEffect, useState } from "react";
import { courceNftAddress } from "./Constants";

export const Referral = ({ address }: { address: string }) => {
  const [ratio, setRatio] = useState<number>(0);
  const [commission, setCommission] = useState<string>("0");

  const courceNftContract = {
    abi: courceNftAbi,
    address: courceNftAddress,
  };

  const { data: ratioData, refetch: refetchRatio } = useReadContract({
    ...courceNftContract,
    functionName: "referrerCommissionRatio",
    args: [address],
  });

  useEffect(() => {
    if (ratioData && typeof ratioData === "number") {
      setRatio(ratioData / 10000);
    }
  }, [ratioData]);

  const { data: commissionData, refetch: refetchCommission } = useReadContract({
    ...courceNftContract,
    functionName: "referrerCommission",
    args: [address],
  });

  useEffect(() => {
    if (commissionData && typeof commissionData === "bigint") {
      setCommission((commissionData / BigInt(1000000)).toString());
    }
  }, [commissionData]);

  const {
    data: hash,
    writeContractAsync: claim,
    isSuccess,
    error,
  } = useWriteContract();
  const handleClaim = () => {
    if (claim) {
      claim({
        ...courceNftContract,
        functionName: "claimCommission",
      });
    } else {
      console.error("claimCommission函数不可用");
    }
  };

  // 当执行cliamCommission成功后重新读取最新的返佣数据
  useEffect(() => {
    if (isSuccess) {
      setTimeout(() => {
        refetchRatio();
        refetchCommission();
      }, 1000); // 1秒后执行，确保交易得到确认
    }
  }, [isSuccess, refetchRatio, refetchCommission]);

  return (
    <div>
      <h2>您的返佣</h2>
      <h3>您的返佣比例：{ratio}%</h3>
      <h3>您的可领取佣金有：{commission} USDT</h3>
      <button className="button" onClick={handleClaim}>
        领取佣金
      </button>
      <p>
        领取佣金交易哈希：
        <a
          href={`https://arbiscan.io/tx/${hash}`}
          target="_blank"
          rel="noopener noreferrer"
        >
          {hash}
        </a>
      </p>
      {error && <p style={{ color: "red" }}>Error: {error.message}</p>}
    </div>
  );
};
