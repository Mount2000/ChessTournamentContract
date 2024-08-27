const { ethers } = require("hardhat");

async function main() {
  const provider = ethers.provider;
  const blockNumber = await provider.getBlockNumber();
  const block = await provider.getBlock(blockNumber);
  const blockTimestamp = block.timestamp;

  const [deployer] = await ethers.getSigners();
  console.log("Deployer:", deployer.address);
  let initialBalance = await deployer.provider.getBalance(deployer.address);
  console.log("Initial ETH balance:", Number(initialBalance), "ETH");

  let FeeCollectorAddress = "0x0000000000000000000000000000000000000000";
  let BookieAddress = "0x0000000000000000000000000000000000000000";
  let WinLossDQAddress = "0x0000000000000000000000000000000000000000";
  let MakerAddress = "0x0000000000000000000000000000000000000000";

  // Deploy FeeCollector contract
  const platformFee = 1;
  const registrationFee = 1;
  const FeeCollector = await ethers.getContractFactory("FeeCollector");
  const feeCollector = await FeeCollector.deploy(platformFee, registrationFee);
  await feeCollector.waitForDeployment();
  const feeCollectorTx = await feeCollector.deploymentTransaction();
  FeeCollectorAddress = feeCollector.target;
  console.log("FeeCollector deployed successfully.");
  console.log(`Deployed to: ${FeeCollectorAddress}`);
  console.log(`Transaction hash: ${feeCollectorTx.hash}`);

  // Deploy Bookie contract
  const startTime = blockTimestamp + 45*60*60;
  const Bookie = await ethers.getContractFactory("Bookie");
  const bookie = await Bookie.deploy(
    FeeCollectorAddress,
    startTime
  );
  await bookie.waitForDeployment();
  const bookieTx = await bookie.deploymentTransaction();
  BookieAddress = bookie.target;
  console.log("Bookie deployed successfully.");
  console.log(`Deployed to: ${BookieAddress}`);
  console.log(`Transaction hash: ${bookieTx.hash}`);

  // Deploy WinLossDQ contract
  const WinLossDQ = await ethers.getContractFactory("WinLossDQ");
  const winLossDQ = await WinLossDQ.deploy(
    BookieAddress
  );
  await winLossDQ.waitForDeployment();
  const winLossDQTx = await winLossDQ.deploymentTransaction();
  WinLossDQAddress = winLossDQ.target;
  console.log("WinLossDQ deployed successfully.");
  console.log(`Deployed to: ${WinLossDQAddress}`);
  console.log(`Transaction hash: ${winLossDQTx.hash}`);

  // Deploy Maker contract
  const Maker = await ethers.getContractFactory("Maker");
  const maker = await Maker.deploy(
    WinLossDQAddress,
    BookieAddress,
  );
  await maker.waitForDeployment();
  const makerTx = await maker.deploymentTransaction();
  MakerAddress = maker.target;
  console.log("Maker deployed successfully.");
  console.log(`Deployed to: ${MakerAddress}`);
  console.log(`Transaction hash: ${makerTx.hash}`);

  /********************** CONTRACT ADDRESS **************************/

  let currentBalance = await deployer.provider.getBalance(deployer.address);
  console.log("Current ETH balance:", Number(currentBalance), "ETH");

  console.log({
    fee: (Number(initialBalance) - Number(currentBalance)) / 10 ** 18,
  });

  console.log({
    FeeCollectorAddress,
    BookieAddress,
    WinLossDQAddress,
    MakerAddress,
  });
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
