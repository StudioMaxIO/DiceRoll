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

    function _updateGameFromRoll(uint256[] memory diceValues)
        internal
        override
    {
        // ???
    }
}
