const hre = require("hardhat");
const deployments = require("../deployments.json");
const network = hre.network.name;
const inquirer = require("inquirer");
const { create } = require("domain");

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

async function playLucky7() {
  console.log("Playing Lucky 7...");

  // Options:
  // Roll, Exit

  await mainMenu();
}

async function playColors() {
  console.log("Playing Colors...");

  // Options:
  // Roll, Exit
  await mainMenu();
}

async function playHighRoll() {
  console.log("Playing High Roll...");

  // Options:
  // enter game, Find open game, create game, find my games, exit to main menu
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
  await mainMenu();
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
