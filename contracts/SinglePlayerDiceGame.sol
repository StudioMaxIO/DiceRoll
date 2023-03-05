// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./DiceRoll.sol";

contract SinglePlayerDiceGame is DiceRoll {
    uint256 public entryFee;
    uint256 public operatorFee;

    uint256 public operatorBalance;

    uint32 public diceQuantity;
    Dice.Die _die;

    mapping(address => uint256) public lastRollID;
    mapping(address => bool) public hasActiveRollID;

    event PoolPayout(
        address indexed recipient,
        uint256 indexed amount,
        uint256 timeStamp
    );

    constructor(
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
        DiceRoll(
            _vrfSubscriptionID,
            _vrfCoordinator,
            _vrfKeyHash,
            _provider,
            _stringToUint
        )
    {
        // use values if sent
        uint256[] memory values = _dieValues.length > 0
            ? _dieValues
            : new uint256[](_dieSides);
        if (_dieValues.length == 0) {
            // set default values if no custom values
            for (uint256 i = 0; i < _dieSides; i++) {
                values[i] = i + 1;
            }
        }
        _die = Dice.Die({values: values, name: _dieName});
        diceQuantity = _diceQuantity;
    }

    // Public
    function play() public {
        require(
            !hasActiveRollID[_msgSender()],
            "player has active roll, cannot play again until resolved"
        );
        require(_senderCanPlay(_msgSender()), "sender not authorized to play");
        // request roll
        lastRollID[_msgSender()] = requestRoll(
            diceQuantity,
            _die.values.length
        );
        hasActiveRollID[_msgSender()] = true;
    }

    function poolBalance() public view returns (uint256) {
        return
            address(this).balance > operatorBalance
                ? address(this).balance - operatorBalance
                : 0;
    }

    // Handle DiceRoll roll delivered
    function rollDelivered(uint256 rollID, uint256[] memory randomness)
        internal
        override
    {
        address roller = rollRequests[rollID].roller;
        if (_rollMeetsWinCondition(rollID)) {
            _payoutPool(roller);
        }
        hasActiveRollID[roller] = false;
    }

    // Functions to override
    function _senderCanPlay(address sender) internal virtual returns (bool) {
        // return true if sender allowed to play, false if not allowed
        return true;
    }

    function _rollMeetsWinCondition(uint256 rollID)
        internal
        virtual
        returns (bool)
    {
        //return true if win condition, false if loses
        return false;
    }

    // Internal
    function _payoutPool(address to) internal {
        // pay out balance of contract
        uint256 payoutAmount = poolBalance();
        (bool sent, ) = to.call{value: payoutAmount}("");
        require(sent, "Failed to withdraw");
        emit PoolPayout(to, payoutAmount, block.timestamp);
    }

    // Admin
    function setEntryFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        entryFee = fee;
    }

    function setOperatorFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        operatorFee = fee;
    }

    // TODO: override after randomness consumer update with virtual function...
    // function withdraw(uint256 amount, address payable to)
    //     public
    //     override
    //     onlyRole(DEFAULT_ADMIN_ROLE)
    // {
    //     (bool sent, ) = to.call{value: amount}("");
    //     require(sent, "Failed to withdraw");
    // }
}
