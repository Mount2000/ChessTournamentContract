const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");
require("dotenv").config();

module.exports = buildModule("VRFRandomNumberModule", (m) => {
  const keyHash = process.env.KEY_HASH;
  const coordinator = process.env.COORDINATOR;
  const subcriptionId = process.env.SUBSCRIPTION_ID;
  const VRFRandomNumber = m.contract("VRFRandomNumber", [keyHash, coordinator, subcriptionId]);

  return { VRFRandomNumber };
});
