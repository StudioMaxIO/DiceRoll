// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./Dice.sol";
import "@luckymachines/game-core/contracts/src/v0.0/RandomnessConsumer.sol";

contract DiceRoll is Dice, RandomnessConsumer {
    event RollRequested(
        address indexed roller,
        uint256 numDice,
        uint256 diceSides,
        uint256 timeStamp
    );

    event RollDelivered(
        address indexed roller,
        uint256 rollID,
        uint256[] rollValues,
        uint256 timestamp
    );

    struct RollRequest {
        address roller;
        bool fulfilled;
        bool exists;
        uint256[] diceValues;
        uint256 diceSides;
        uint256 diceTotal;
    }

    // mapping from request id
    mapping(uint256 => uint256) public rollIDs;
    // mapping from roll ID
    mapping(uint256 => RollRequest) public rollRequests;

    // internal id for tracking unique roll requests
    uint256 _rollID;

    constructor(
        uint64 _vrfSubscriptionID,
        address _vrfCoordinator,
        bytes32 _vrfKeyHash,
        address _provider,
        address _stringToUint
    )
        RandomnessConsumer(
            _vrfSubscriptionID,
            _vrfCoordinator,
            _vrfKeyHash,
            _provider,
            _stringToUint
        )
    {}

    // roll info
    function rollValues(uint256 rollID)
        external
        view
        returns (uint256[] memory)
    {
        return rollRequests[rollID].diceValues;
    }

    function requestRoll(
        address roller,
        uint32 numDice,
        uint256 diceSides
    ) internal returns (uint256 rollID) {
        _setNumWords(numDice);
        rollID = _requestRoll(roller, numDice, diceSides);
    }

    // Override this function to react when dice roll is delivered
    function rollDelivered(uint256 rollID, uint256[] memory diceValues)
        internal
        virtual
    {}

    function fulfillRandomness(
        uint256 _requestId,
        uint256[] memory _randomness,
        string memory _seed,
        uint64 _time
    ) internal override {
        super.fulfillRandomness(_requestId, _randomness, _seed, _time);
        // turn each random number into dice value
        uint256 rollID = rollIDs[_requestId];
        RollRequest storage rr = rollRequests[rollID];
        uint256[] memory diceValues = new uint256[](_randomness.length);
        // set to value 1 - num of sides
        for (uint256 i = 0; i < rr.diceValues.length; i++) {
            rr.diceValues[i] = (_randomness[i] % rr.diceSides) + 1;
        }
        rr.fulfilled = true;
        rr.diceTotal = sumValues(rr.diceValues);

        rollDelivered(rollID, diceValues);
        emit RollDelivered(
            rollRequests[rollID].roller,
            rollID,
            diceValues,
            block.timestamp
        );
    }

    function _requestRoll(
        address roller,
        uint32 numDice,
        uint256 diceSides
    ) internal returns (uint256 requestID) {
        ++_rollID;
        requestID = requestRandomness(_rollID, address(this));
        rollIDs[requestID] = _rollID;
        rollRequests[_rollID] = RollRequest({
            roller: roller,
            fulfilled: false,
            exists: true,
            diceValues: new uint256[](numDice),
            diceSides: diceSides,
            diceTotal: 0
        });
        emit RollRequested(roller, numDice, diceSides, block.timestamp);
    }

    // Helper
    function sumValues(uint256[] memory diceValues)
        internal
        pure
        returns (uint256 total)
    {
        for (uint256 i = 0; i < diceValues.length; i++) {
            total += diceValues[i];
        }
    }
}
