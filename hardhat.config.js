require("@nomicfoundation/hardhat-toolbox");
require("dotenv").config();

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.20",
  networks: {
    AMOY: {
      url: String(process.env.AMOY_RPC_URL),
      accounts: [String(process.env.PRIVATE_KEY)]
    },
    ALEPH_ZERO: {
      url: String(process.env.ALEPH_ZERO_RPC_URL),
      accounts: [String(process.env.PRIVATE_KEY)]
    }
  }
};
