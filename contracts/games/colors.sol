// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "../SinglePlayerDiceGame.sol";

// About game:
// Winning color changes each time someone rolls it.
// Roll color to win the pool

contract Colors is SinglePlayerDiceGame {
    string[] _colors = ["Red", "Orange", "Yellow", "Green", "Blue", "Purple"];
    uint8 _colorIndex;

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

    function currentColor() public view returns (string memory color) {
        color = _colors[_colorIndex];
    }

    // override functions for custom behavior
    // This is all we need to create a new game

    function _rollMeetsWinCondition(RollRequest memory rollRequest)
        internal
        override
        returns (bool)
    {
        bool winner = false;
        uint256 diceValueOfColor = _colorIndex + 1;
        winner = rollRequest.diceTotal == diceValueOfColor;
        if (winner) {
            _updateColor();
        }
        return winner;
    }

    function _updateColor() internal {
        if (_colorIndex < (_colors.length - 1)) {
            ++_colorIndex;
        } else {
            _colorIndex = 0;
        }
    }
}
