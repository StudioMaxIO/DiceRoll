// 1.
// Deploy Lucky 7
// set entry fee
// set operator fee
// 2.
// Deploy Colors
// set entry fee
// set operator fee
// 3.
// Deploy High Roller
// set entry fee
// set operator fee

const hre = require("hardhat");
const deployments = require("../deployments.json");
const vrf = require("../VRF.json");
const network = hre.network.name;
const fs = require("fs");

async function main() {
  // Fees
  let entryFee = "0.1";
  let operatorFee = "0.01";
  // values needed for deployments
  const accounts = await ethers.provider.listAccounts();
  let operator = accounts[0];
  console.log("Operator:", operator);
  let diceQuantity = 2;
  let dieSides = 6;
  let dieValues = []; // default
  let dieName = ""; // default
  let dieLabels = []; // default
  const vrfSubscriptionID = vrf[network].VRF_SUBSCRIPTION_ID;
  const vrfCoordinator = vrf[network].VRF_COORDINATOR;
  const vrfKeyHash = vrf[network].VRF_KEY_HASH;
  const bandVRFProvider = vrf[network].BAND_VRF_PROVIDER;
  const stringToUint = vrf[network].STRING_TO_UINT;

  //
  // Lucky 7
  //
  const Lucky7 = await hre.ethers.getContractFactory("Lucky7");

  console.log("Deploying Lucky 7...");
  const lucky7 = await Lucky7.deploy(
    operator,
    diceQuantity,
    dieSides,
    dieValues,
    dieName,
    dieLabels,
    vrfSubscriptionID,
    vrfCoordinator,
    vrfKeyHash,
    bandVRFProvider,
    stringToUint
  );
  await lucky7.deployed();
  console.log("Lucky 7 deployed to", lucky7.address);
  deployments[network].LUCKY_7_GAME = lucky7.address;

  let tx = await lucky7.setEntryFee(hre.ethers.utils.parseEther(entryFee));
  await tx.wait();
  tx = await lucky7.setOperatorFee(hre.ethers.utils.parseEther(operatorFee));

  //
  // Colors
  //
  diceQuantity = 1;
  dieName = "colors";
  const Colors = await hre.ethers.getContractFactory("Colors");

  console.log("Deploying Colors...");
  const colorLabels = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"];
  const colors = await Colors.deploy(
    operator,
    diceQuantity,
    dieSides,
    dieValues,
    dieName,
    colorLabels,
    vrfSubscriptionID,
    vrfCoordinator,
    vrfKeyHash,
    bandVRFProvider,
    stringToUint
  );
  await colors.deployed();
  console.log("Colors deployed to", colors.address);
  deployments[network].COLORS_GAME = colors.address;

  tx = await colors.setEntryFee(hre.ethers.utils.parseEther(entryFee));
  await tx.wait();
  tx = await colors.setOperatorFee(hre.ethers.utils.parseEther(operatorFee));

  try {
    const path = `${process.cwd()}/deployments.json`;
    fs.writeFileSync(path, JSON.stringify(deployments, null, 4));
  } catch (err) {
    console.log(
      `unable to save deployments.json to ${path}. Error: ${err.message}`
    );
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
