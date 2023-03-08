require("@nomicfoundation/hardhat-toolbox");
require("hardhat-contract-sizer");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  networks: {
    hardhat: {},
    hh: {
      url: "http://127.0.0.1:8545",
      accounts: [
        "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
        "0x59c6995e998f97a5a0044966f0945389dc9e86dae88c7a8412f4603b6b78690d",
        "0x5de4111afa1a4b94908f83103eb1f1706367c2e68ca870fc3fb9a804cdab365a"
      ]
    },
    ftm_test: {
      url: process.env.RPC_URL_FANTOM_TEST,
      accounts: [process.env.PRIVATE_KEY_FANTOM_TEST],
      chainId: 4002
    },
    ftm: {
      url: process.env.RPC_URL_FANTOM,
      accounts: [process.env.PRIVATE_KEY_FANTOM],
      chainId: 250
    }
  },
  solidity: {
    version: "0.8.9",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  }
};
