// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../SinglePlayerDiceGame.sol";

// About Game:
// Player pays entry fee and rolls 2 dice
// If dice value == 7, player gets prize pool, otherwise prize pool grows

contract Lucky7 is SinglePlayerDiceGame {
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
        SinglePlayerDiceGame(
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
    function _senderCanPlay(address sender) internal override returns (bool) {
        return true;
    }

    function _rollMeetsWinCondition(uint256[] memory diceValues)
        internal
        override
        returns (bool)
    {
        return false;
    }
}
