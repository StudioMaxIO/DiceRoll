// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

interface ISinglePlayerDiceGame {
    function hasActiveRollID(address playerAddress)
        external
        view
        returns (bool);

    function lastRollID(address playerAddress) external view returns (uint256);

    function play() external payable;

    function poolBalance() external view returns (uint256);
}
