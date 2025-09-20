import { courceNftAbi } from "../abis/courceNFT";
import { useReadContract, useWriteContract } from "wagmi";
import { useEffect, useState } from "react";
import { courceNftAddress } from "./Constants";

export const Consume = ({ address }: { address: string }) => {
  const [firstTokenIdString, setFirstTokenIdString] = useState<string>("null");
  const [tokenId, setTokenId] = useState<string>("");
  const [code, setCode] = useState<string>("");

  // 计算按钮是否可点击
  const isButtonDisabled = tokenId.trim() === "" || code.trim() === "";

  const { data: tokenIdData } = useReadContract({
    abi: courceNftAbi,
    address: courceNftAddress,
    functionName: "tokenOfOwnerByIndex",
    args: [address, 0],
  });

  useEffect(() => {
    console.log("typeof tokenIdData:", typeof tokenIdData);
    console.log("tokenIdData:", tokenIdData);
    if (tokenIdData && typeof tokenIdData === "bigint") {
      setFirstTokenIdString(tokenIdData.toString());
    }
  }, [tokenIdData]);

  const { data: hash, writeContractAsync: consume, error } = useWriteContract();
  const handleConsume = () => {
    if (consume) {
      consume({
        abi: courceNftAbi,
        address: courceNftAddress,
        functionName: "consume",
        args: [tokenId, code],
      });
    } else {
      console.error("consume函数不可用");
    }
  };

  const submitConsume = (e: React.FormEvent) => {
    e.preventDefault(); // 阻止默认表单提交行为
    handleConsume();
  };

  return (
    <div>
      <h3>Step3：核销NFT</h3>
      <p>可核销的NFT tokenId：{firstTokenIdString}</p>
      <p>code需要找钢哥（keegan704）确认</p>
      <form onSubmit={submitConsume}>
        <input
          type="text"
          value={tokenId}
          onChange={(e) => setTokenId(e.target.value)}
          placeholder="tokenId"
          style={{ marginRight: "10px" }} // Add margin to the right
        />
        <input
          type="text"
          value={code}
          onChange={(e) => setCode(e.target.value)}
          placeholder="code"
          style={{ marginRight: "10px" }} // Add margin to the right
        />
        <button
          className={`button ${isButtonDisabled ? "disabled" : ""}`}
          type="submit"
          disabled={isButtonDisabled}
        >
          核销
        </button>
      </form>
      <p>
        核销交易哈希：
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
