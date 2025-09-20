import { usdtAbi } from "../abis/usdt";
import { useReadContract, useWriteContract } from "wagmi";
import { useEffect, useState } from "react";
import { usdtAddress, courceNftAddress } from "./Constants";

export const Approve = ({
  address,
  price,
}: {
  address: string;
  price: bigint;
}) => {
  const [allowance, setAllowance] = useState<bigint | null>(null);
  const [allowanceString, setAllowanceString] = useState<string>("0");

  const { data: allowanceData, refetch } = useReadContract({
    abi: usdtAbi,
    address: usdtAddress,
    functionName: "allowance",
    args: [address, courceNftAddress],
  });

  useEffect(() => {
    if (allowanceData && typeof allowanceData === "bigint") {
      setAllowance(allowanceData);
      setAllowanceString((allowanceData / BigInt(1000000)).toString());
    }
  }, [allowanceData]);

  const {
    data: hash,
    writeContractAsync: approve,
    isSuccess,
    error,
  } = useWriteContract();
  const handleApprove = () => {
    if (approve) {
      approve({
        abi: usdtAbi,
        address: usdtAddress,
        functionName: "approve",
        args: [courceNftAddress, price],
      });
    } else {
      console.error("approve函数不可用");
    }
  };

  // 当执行approve成功后重新读取最新的授权额度
  useEffect(() => {
    if (isSuccess) {
      setTimeout(() => {
        refetch(); // 重新读取合约状态
      }, 1000); // 1秒后执行，确保交易得到确认
    }
  }, [isSuccess, refetch]);

  return (
    <div>
      <h3>Step1：USDT授权</h3>
      <p>已授权额度：{allowanceString} USDT</p>
      {(
        allowance && typeof allowance === "bigint" ? allowance < price : true
      ) ? (
        <div>
          <p>授权额度不足，请先进行授权</p>
          <button className="button" onClick={handleApprove}>
            授权
          </button>
          <p>
            授权交易哈希：
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
      ) : (
        <p>已有足够授权额度，无需再授权</p>
      )}
    </div>
  );
};
