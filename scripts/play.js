const hre = require("hardhat");
const deployments = require("../deployments.json");
const network = hre.network.name;
const inquirer = require("inquirer");

// Player Info
let player;

// Game Contracts
let LUCKY_7;
let COLORS;
let HIGH_ROLL;

// Setup
async function attachGameContracts() {
  const Lucky7 = await ethers.getContractFactory("Lucky7");
  LUCKY_7 = Lucky7.attach(deployments[network].LUCKY_7_GAME);

  /*
  const Colors = await ethers.getContractFactory("Colors");
  COLORS = Colors.attach(deployments[network].COLORS_GAME);

  const HighRoll = await ethers.getContractFactory("HighRoll");
  HIGH_ROLL = HighRoll.attach(deployments[network].HIGH_ROLL_GAME);
  */
}

// Main Menu
async function mainMenu() {
  let questions = [];
  const whichGame = {
    type: "list",
    name: "gameChoice",
    message: "Which game would you like to play?",
    choices: ["Lucky 7", "Colors", "High Roll", "Exit"],
    default: "Lucky 7"
  };
  questions.push(whichGame);
  let answers = await inquirer.prompt(questions);
  switch (answers.gameChoice) {
    case "Lucky 7":
      await playLucky7();
      break;
    case "Colors":
      await playColors();
      break;
    case "High Roll":
      await playHighRoll();
      break;
    case "Exit":
    default:
      process.exit(0);
      break;
  }
}

// Lucky 7
async function playLucky7() {
  console.log("\nLucky 7\n");

  let questions = [];
  const gameChoice = {
    type: "list",
    name: "gameChoice",
    message: "What would you like to do?",
    choices: ["Roll", "Check Roll", "Exit"],
    default: "Roll"
  };
  questions.push(gameChoice);
  let answers = await inquirer.prompt(questions);

  switch (answers.gameChoice) {
    case "Roll":
      await rollLucky7();
      break;
    case "Check Roll":
      await checkRollLucky7();
      break;
    case "Exit":
    default:
      await mainMenu();
      break;
  }
}

async function rollLucky7() {
  let tx = await LUCKY_7.play();
  await tx.wait();
  let useMock = await LUCKY_7.useMockVRF();
  if (useMock) {
    tx = await LUCKY_7.fulfillMockRandomness();
    tx.wait();
  }
  console.log("Roll requested. Check roll to see if you won.");
  await playLucky7();
}

async function checkRollLucky7() {
  const lastRollID = await LUCKY_7.lastRollID(player);
  if (Number(lastRollID) > 0) {
    console.log("Last roll ID:", lastRollID.toString());
    const hasActiveRoll = await LUCKY_7.hasActiveRollID(player);
    if (hasActiveRoll) {
      console.log("Roll has been requested. Awaiting randomness...");
    } else {
      let playerRoll = await LUCKY_7.rollRequests(lastRollID);
      console.log("Player Roll:", playerRoll);
      console.log("Values:", playerRoll.diceValues);
      if (Number(playerRoll.diceTotal) == 7) {
        console.log("Congratulations, you won!");
      } else {
        console.log("Sorry, didn't win this time. Try again.");
      }
    }
  } else {
    console.log("No rolls for player.");
  }
  await playLucky7();
}

// Colors
async function playColors() {
  console.log("Playing Colors...");

  // Options:
  // Roll, Check Roll, Exit
  await mainMenu();
}

// High Roll
async function playHighRoll() {
  console.log("Playing High Roll...");
  let questions = [];
  const options = {
    type: "list",
    name: "gameOptions",
    message: "What would you like to do?",
    choices: [
      "Find open game",
      "Enter game (with ID)",
      "Create game",
      "Find my games",
      "Main Menu"
    ],
    default: "Find open game"
  };
  questions.push(options);
  let answers = await inquirer.prompt(questions);
  switch (answers.gameOptions) {
    case "Find open game":
      await findOpenGames();
      break;
    case "Enter game (with ID)":
      await enterGame();
      break;
    case "Create game":
      await createGame();
      break;
    case "Find my games":
      await findMyGames();
      break;
    case "Main Menu":
    default:
      await mainMenu();
      break;
  }
}

async function findOpenGames() {
  console.log("Find open games...");
  await playHighRoll();
}

async function enterGame() {
  let questions = [];
  const gameID = {
    type: "input",
    name: "gameID",
    message: "Game ID:",
    default: "1"
  };
  questions.push(gameID);
  let answers = await inquirer.prompt(questions);
  await startHighRollGame(answers.gameID);
}

async function createGame() {
  console.log("Create game...");
  await playHighRoll();
}

async function findMyGames() {
  console.log("Find my games...");
  await playHighRoll();
}

async function startHighRollGame(gameID) {
  console.log("Start high roll game:", gameID);
  await playHighRoll();
  // Options
  // Roll, Exit
}

async function main() {
  const accounts = await ethers.provider.listAccounts();
  player = accounts[0];
  await attachGameContracts();
  await mainMenu();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
