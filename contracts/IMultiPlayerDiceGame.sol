// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface IMultiPlayerDiceGame {
    struct GameInfo {
        uint256 gameID; // unique ID of the game
        uint256 gameSize; // how many players can enter
        address[] players; // players entered in game
        uint256 poolValue; // total value of pool prize (if all players enter)
        bool complete; // is the game complete
        address winner; // address of the winner if game is complete
        bool paid; // has the pool prize been paid out
    }

    function play(uint256 gameID) external payable;

    function poolBalance(uint256 gameID) external view returns (uint256);

    function findGame()
        external
        view
        returns (GameInfo[] memory availableGames);
}
