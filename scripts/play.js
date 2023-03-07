const hre = require("hardhat");
const deployments = require("../deployments.json");
const network = hre.network.name;
const inquirer = require("inquirer");

let gameChoice;

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
  gameChoice = answers.gameChoice;
  switch (gameChoice) {
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
  await mainMenu();
}

async function playColors() {
  console.log("Playing Colors...");
  await mainMenu();
}

async function playHighRoll() {
  console.log("Playing High Roll...");
  await mainMenu();
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
