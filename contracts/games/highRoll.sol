// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../MultiPlayerDiceGame.sol";

// About game:
// multiple people enter
// highest roll wins
// if a tie occurs, rolls continue until a winner is determined
// 1 dice rolled per person
contract HighRoll is MultiPlayerDiceGame {
    constructor(
        address operator,
        uint32 _diceQuantity,
        uint256 _dieSides, // optional if using default 1-n
        uint256[] memory _dieValues, // overrides dieSides if set
        string memory _dieName, // optional
        string[] memory _dieLabels, // optional
        uint64 _vrfSubscriptionID,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash,
        address _provider,
        address _stringToUint
    )
        MultiPlayerDiceGame(
            operator,
            _diceQuantity,
            _dieSides,
            _dieValues,
            _dieName,
            _dieLabels,
            _vrfSubscriptionID,
            _vrfCoordinator,
            _vrfKeyHash,
            _provider,
            _stringToUint
        )
    {}

    // override functions for custom behavior
    // This is all we need to create a new game

    function _updateGameFromRoll(uint256[] memory diceValues, uint256 gameID)
        internal
        override
    {
        GameInfo storage game = games[gameID];
        uint256 playerCount = 0;
        for (uint256 i = 0; i < game.players.length; i++) {
            if (!finishedGame[gameID][game.players[i]]) {
                ++playerCount;
            }
        }

        uint256 pIndex = 0;
        address[] memory activePlayers = new address[](playerCount);
        uint256[] memory activeRollValues = new uint256[](playerCount);
        for (uint256 i = 0; i < playerCount; i++) {
            if (!finishedGame[gameID][game.players[i]]) {
                activePlayers[pIndex] = game.players[i];
                activeRollValues[pIndex] = diceValues[i];
                ++pIndex;
            }
        }
        uint256 highNumber = highestNumber(activeRollValues);
        uint256 totalWinners = 0;
        address winner;
        for (uint256 i = 0; i < activePlayers.length; i++) {
            if (activeRollValues[i] == highNumber) {
                ++totalWinners;
                winner = activePlayers[i];
            } else {
                finishedGame[gameID][activePlayers[i]] = true;
            }
        }

        if (totalWinners == 1) {
            game.complete = true;
            game.winner = winner;
        }
    }

    function highestNumber(uint256[] memory numbers)
        internal
        pure
        returns (uint256 highNumber)
    {
        highNumber = numbers[0];
        if (numbers.length > 1) {
            for (uint256 i = 1; i < numbers.length; i++) {
                if (highNumber < numbers[i]) {
                    highNumber = numbers[i];
                }
            }
        }
    }
}
