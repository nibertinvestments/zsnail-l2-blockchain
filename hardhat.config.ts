import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-viem";
import "@nomicfoundation/hardhat-ignition";
import "@nomicfoundation/hardhat-verify";
import "dotenv/config";

const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.28",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
      viaIR: true,
    },
  },
  
  networks: {
    hardhat: {
      type: "edr-simulated",
      chainId: 31337,
    },
    localhost: {
      type: "http",
      url: "http://127.0.0.1:8545",
      chainId: 31337,
    },
    sepolia: {
      type: "http",
      url: process.env.SEPOLIA_RPC_URL || "https://eth-sepolia.g.alchemy.com/v2/your-api-key",
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : [],
      chainId: 11155111,
    },
  },
  
  paths: {
    sources: "./contracts",
    tests: "./test",
    cache: "./cache",
    artifacts: "./artifacts",
  },
  
  ignition: {
    strategyConfig: {
      create2: {
        salt: "0x0000000000000000000000000000000000000000000000000000000000000001",
      },
    },
  },
};

export default config;