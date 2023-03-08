const hre = require("hardhat");
const deployments = require("../deployments.json");
const network = hre.network.name;
const inquirer = require("inquirer");
const {
  latest
} = require("@nomicfoundation/hardhat-network-helpers/dist/src/helpers/time");

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

  const Colors = await ethers.getContractFactory("Colors");
  COLORS = Colors.attach(deployments[network].COLORS_GAME);

  const HighRoll = await ethers.getContractFactory("HighRoll");
  HIGH_ROLL = HighRoll.attach(deployments[network].HIGH_ROLL_GAME);
}

// Main Menu
async function mainMenu() {
  console.log("\nMain Menu\n");
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
    choices: ["Roll", "Check Roll", "Check Pool", "Main Menu"],
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
    case "Check Pool":
      await checkPoolLucky7();
      break;
    case "Main Menu":
    default:
      await mainMenu();
      break;
  }
}

async function rollLucky7() {
  // get entry fee
  let entryFee = await LUCKY_7.entryFee();
  let tx = await LUCKY_7.play({ value: entryFee });
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
    // console.log("Last roll ID:", lastRollID.toString());
    const hasActiveRoll = await LUCKY_7.hasActiveRollID(player);
    if (hasActiveRoll) {
      console.log("Roll has been requested. Awaiting randomness...");
    } else {
      let playerRoll = await LUCKY_7.rollRequests(lastRollID);
      console.log("Roll Total:", playerRoll.diceTotal.toString());
      let rollValues = await LUCKY_7.rollValues(lastRollID);
      console.log("Dice Values:", rollValues.toString());
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

async function checkPoolLucky7() {
  const poolBalance = await LUCKY_7.poolBalance();
  console.log("Pool balance:", hre.ethers.utils.formatEther(poolBalance));
  await playLucky7();
}

// Colors
async function playColors() {
  console.log("\nColors\n");

  let questions = [];
  const gameChoice = {
    type: "list",
    name: "gameChoice",
    message: "What would you like to do?",
    choices: ["Roll", "Check Roll", "Check Pool", "Main Menu"],
    default: "Roll"
  };
  questions.push(gameChoice);
  let answers = await inquirer.prompt(questions);

  switch (answers.gameChoice) {
    case "Roll":
      await rollColors();
      break;
    case "Check Roll":
      await checkRollColors();
      break;
    case "Check Pool":
      await checkPoolColors();
      break;
    case "Main Menu":
    default:
      await mainMenu();
      break;
  }
}

async function rollColors() {
  // get entry fee
  let entryFee = await COLORS.entryFee();
  let winningColor = await COLORS.currentColor();
  console.log("Winning color:", winningColor);
  let tx = await COLORS.play({ value: entryFee });
  await tx.wait();
  let useMock = await COLORS.useMockVRF();
  if (useMock) {
    tx = await COLORS.fulfillMockRandomness();
    tx.wait();
  }
  console.log("Roll requested. Check roll to see if you won.");
  await playColors();
}

async function checkRollColors() {
  const lastRollID = await COLORS.lastRollID(player);
  if (Number(lastRollID) > 0) {
    // console.log("Last roll ID:", lastRollID.toString());
    const hasActiveRoll = await COLORS.hasActiveRollID(player);
    if (hasActiveRoll) {
      console.log("Roll has been requested. Awaiting randomness...");
    } else {
      let playerRoll = await COLORS.rollRequests(lastRollID);
      let rollTotal = playerRoll.diceTotal;
      let colorRolled = await COLORS.dieLabels("colors", rollTotal);
      console.log("Color rolled:", colorRolled);
      const winner = await COLORS.winningRolls(lastRollID);
      if (winner) {
        console.log("Congratulations, you won!");
      } else {
        console.log("Sorry, didn't win this time. Try again.");
      }
    }
  } else {
    console.log("No rolls for player.");
  }
  await playColors();
}

async function checkPoolColors() {
  const poolBalance = await COLORS.poolBalance();
  console.log("Pool balance:", hre.ethers.utils.formatEther(poolBalance));
  await playColors();
}

// High Roll
async function playHighRoll() {
  console.log("\nHigh Roll\n");
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
  const games = await HIGH_ROLL.findGame();
  console.log("Open games:", games);
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
  let questions = [];
  const totalPlayers = {
    type: "input",
    name: "totalPlayers",
    message: "Number of players:",
    default: "2"
  };
  questions.push(totalPlayers);
  let answers = await inquirer.prompt(questions);
  console.log("Creating game...");
  let tx = await HIGH_ROLL.createGame(answers.totalPlayers);
  await tx.wait();

  // get latest game
  const allPlayerGames = await HIGH_ROLL.findGamesForPlayer(player);
  const latestGameID = allPlayerGames[allPlayerGames.length - 1];
  console.log("Created game with ID:", latestGameID.toString());
  console.log("Starting game...");
  await startHighRollGame(latestGameID);
}

async function findMyGames() {
  const allPlayerGames = await HIGH_ROLL.findGamesForPlayer(player);
  console.log("My games:", allPlayerGames);
  await playHighRoll();
}

async function startHighRollGame(gameID) {
  // check if player is in game, if not try to register
  console.log(`\nHigh Roll, game ${gameID.toString()}\n`);
  let isRegistered = await HIGH_ROLL.isInGame(gameID, player);
  if (!isRegistered) {
    try {
      let entryFee = await HIGH_ROLL.entryFee();
      let tx = await HIGH_ROLL.joinGame(gameID, { value: entryFee });
      await tx.wait();
      isRegistered = await HIGH_ROLL.isInGame(gameID, player);
    } catch (err) {
      console.log("Error joining game:");
      console.log(err.message);
    }
  }

  if (isRegistered) {
    let questions = [];
    const options = {
      type: "list",
      name: "gameOptions",
      message: "What would you like to do?",
      choices: ["Game Status", "Roll", "Check Pool", "Exit"],
      default: "Game Status"
    };
    questions.push(options);
    let answers = await inquirer.prompt(questions);
    switch (answers.gameOptions) {
      case "Game Status":
        await gameStatusHighRoll(gameID);
        break;
      case "Roll":
        await rollHighRoll(gameID);
        break;
      case "Check Pool":
        await checkPoolHighRoll(gameID);
        break;
      case "Exit":
      default:
        await playHighRoll();
        break;
    }
  } else {
    await playHighRoll();
  }
}

async function gameStatusHighRoll(gameID) {
  let game = await HIGH_ROLL.games(gameID);
  // console.log("Game", gameID);
  console.log(game);
  console.log("Game ID:", game.gameID.toString());
  console.log("Game Size:", game.gameSize.toString());
  console.log("Pool Value:", hre.ethers.utils.formatEther(game.poolValue));
  console.log("Game Complete:", game.complete);
  console.log(
    "Winner:",
    game.winner == "0x0000000000000000000000000000000000000000"
      ? "Game in progress..."
      : game.winner
  );
  console.log("Winner Paid:", game.paid);
  await startHighRollGame(gameID);
}

async function rollHighRoll(gameID) {
  console.log("Requesting roll...");
  try {
    let tx = await HIGH_ROLL.play(gameID);
    await tx.wait();
    console.log("Roll requested. Check game status for updates.");
  } catch (err) {
    console.log(err.reason);
  }
  await startHighRollGame(gameID);
}

async function checkPoolHighRoll(gameID) {
  let poolBalance = await HIGH_ROLL.poolBalance(gameID);
  console.log(
    `Game ${gameID} pool balance:${hre.ethers.utils.formatEther(poolBalance)}`
  );
  await startHighRollGame(gameID);
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
