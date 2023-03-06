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
    }

    // mapping from request id
    mapping(uint256 => uint256) rollIDs;
    // mapping from roll ID
    mapping(uint256 => RollRequest) rollRequests;

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
        uint256[] memory diceValues = new uint256[](_randomness.length);
        // use randomness to calculate dice values

        rollRequests[rollID].fulfilled = true;
        rollRequests[rollID].diceValues = diceValues;

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
            diceSides: diceSides
        });
        emit RollRequested(roller, numDice, diceSides, block.timestamp);
    }
}
