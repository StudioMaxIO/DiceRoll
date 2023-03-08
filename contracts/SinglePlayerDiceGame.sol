// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./DiceRoll.sol";

contract SinglePlayerDiceGame is DiceRoll {
    bytes32 public OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public entryFee;
    uint256 public operatorFee;

    uint256 public operatorBalance;

    uint32 public diceQuantity;
    Dice.Die _die;

    mapping(address => uint256) public lastRollID;
    mapping(address => bool) public hasActiveRollID;
    mapping(uint256 => bool) public winningRolls;

    event PoolPayout(
        address indexed recipient,
        uint256 indexed amount,
        uint256 timeStamp
    );

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
        DiceRoll(
            _vrfSubscriptionID,
            _vrfCoordinator,
            _vrfKeyHash,
            _provider,
            _stringToUint
        )
    {
        _setupRole(OPERATOR_ROLE, operator);
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
        if (_dieLabels.length > 0) {
            createMappedDie(_die, _dieLabels);
        }
        diceQuantity = _diceQuantity;
    }

    // Public
    function play() external payable {
        require(
            !hasActiveRollID[_msgSender()],
            "player has active roll, cannot play again until resolved"
        );
        require(_senderCanPlay(_msgSender()), "sender not authorized to play");
        require(msg.value >= entryFee, "Entry fee below minimum");

        // take operator fee
        operatorBalance += operatorFee;

        // request roll
        lastRollID[_msgSender()] = requestRoll(
            _msgSender(),
            diceQuantity,
            _die.values.length
        );
        hasActiveRollID[_msgSender()] = true;
    }

    function poolBalance() external view returns (uint256) {
        return
            address(this).balance > operatorBalance
                ? address(this).balance - operatorBalance
                : 0;
    }

    // Handle DiceRoll roll delivered
    function rollDelivered(
        uint256 rollID,
        uint256[] memory /*diceValues*/
    ) internal override {
        RollRequest memory rr = rollRequests[rollID];
        address roller = rr.roller;
        if (_rollMeetsWinCondition(rr)) {
            winningRolls[rollID] = true;
            _payoutPool(roller);
        }
        hasActiveRollID[roller] = false;
    }

    // Override
    function _rollMeetsWinCondition(
        RollRequest memory /*rollRequest*/
    ) internal virtual returns (bool) {
        //return true if win condition, false if loses
        return false;
    }

    // Optional Override
    function _senderCanPlay(address sender) internal virtual returns (bool) {
        // return true if sender allowed to play, false if not allowed
        if (sender != address(0)) {
            return true;
        } else {
            return false;
        }
    }

    // Internal
    function _payoutPool(address to) internal {
        // pay out balance of contract
        uint256 payoutAmount = this.poolBalance();
        (bool sent, ) = to.call{value: payoutAmount}("");
        require(sent, "Failed to withdraw");
        emit PoolPayout(to, payoutAmount, block.timestamp);
    }

    // Admin
    function setEntryFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (operatorFee > 0) {
            require(
                fee > operatorFee,
                "entry fee must be greater than operator fee"
            );
        }
        entryFee = fee;
    }

    function setOperatorFee(uint256 fee) public onlyRole(DEFAULT_ADMIN_ROLE) {
        require(entryFee > fee, "Operator fee must be less than entry fee");
        operatorFee = fee;
    }

    function withdraw(
        uint256 amount,
        address payable to
    ) public override onlyRole(OPERATOR_ROLE) {
        require(amount <= operatorBalance);
        (bool sent, ) = to.call{value: amount}("");
        require(sent, "Failed to withdraw");
    }
}
