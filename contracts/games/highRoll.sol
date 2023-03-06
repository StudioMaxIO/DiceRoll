// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../MultiPlayerDiceGame.sol";

// About game:
// Player pays entry fee and rolls 2 dice
// If dice value == 7, player gets prize pool, otherwise prize pool grows
// multiple people enter
// highest roll wins
// if a tie occurs, rolls continue until a winner is determined

contract HighRoll is MultiPlayerDiceGame {
    constructor(
        address operator,
        uint32 _diceQuantity,
        uint256 _dieSides, // optional if using default 1-n
        uint256[] memory _dieValues, // overrides diceSides if set
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
    function _senderCanPlay(
        address, /*sender*/
        uint256 /*gameID*/
    ) internal override returns (bool) {
        return true;
    }

    function _updateGameFromRoll(uint256[] memory diceValues)
        internal
        override
    {}
}
