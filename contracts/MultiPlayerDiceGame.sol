// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.9;

import "./DiceRoll.sol";

contract MultiPlayerDiceGame is DiceRoll {
    bytes32 public OPERATOR_ROLE = keccak256("OPERATOR_ROLE");

    uint256 public entryFee;
    uint256 public operatorFee;
    uint256 public operatorBalance;

    uint32 public diceQuantity;
    Dice.Die _die;

    // mapping from game ID
    mapping(uint256 => uint256) _poolBalances;
    mapping(uint256 => uint256) public gameRollIDs;
    mapping(uint256 => bool) public hasActiveRoll;
    mapping(uint256 => GameInfo) public games;

    // mapping from roll ID
    mapping(uint256 => uint256) gameIDsFromRollID;

    // mapping from game ID => player address
    mapping(uint256 => mapping(address => bool)) public isInGame;
    mapping(uint256 => mapping(address => bool)) public finishedGame; // finshed whether win or lose
    mapping(uint256 => mapping(address => bool)) public entryFeePaid;
    // mapping from player address
    mapping(address => uint256[]) playerGames;

    // current value for setting new game IDs
    uint256 _gameID;
    // list of all games that have ever been created
    GameInfo[] _allGames;

    event PoolPayout(
        address indexed recipient,
        uint256 indexed amount,
        uint256 timeStamp
    );

    struct GameInfo {
        uint256 gameID; // unique ID of the game
        uint256 gameSize; // how many players can enter
        address[] players; // players entered in game
        uint256 poolValue; // total value of pool prize (if all players enter)
        bool complete; // is the game complete
        address winner; // address of the winner if game is complete
        bool paid; // has the pool prize been paid out
    }

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
    function createGame(uint256 totalPlayers) public payable {
        require(totalPlayers > 1, "game must have at least 2 players");
        ++_gameID;
        GameInfo memory newGame = GameInfo({
            gameID: _gameID,
            gameSize: totalPlayers,
            players: new address[](0),
            poolValue: ((entryFee * totalPlayers) - operatorFee),
            complete: false,
            winner: address(0),
            paid: false
        });
        games[_gameID] = newGame;
        _allGames.push(newGame);
        if (!entryFeePaid[_gameID][_msgSender()]) {
            require(msg.value >= entryFee, "minimum entry fee not sent");
            entryFeePaid[_gameID][_msgSender()] = true;
        }
        _enterPlayer(_gameID, _msgSender());
    }

    function findGame()
        external
        view
        returns (GameInfo[] memory availableGames)
    {
        uint256 gameCount = 0;
        for (uint256 i = 0; i < _allGames.length; i++) {
            GameInfo memory game = _allGames[i];
            if (!game.complete && game.players.length < game.gameSize) {
                // game can be added to availableGames
                ++gameCount;
            }
        }
        availableGames = new GameInfo[](gameCount);
        uint256 index = 0;
        for (uint256 i = 0; i < _allGames.length; i++) {
            GameInfo memory game = _allGames[i];
            if (!game.complete && game.players.length < game.gameSize) {
                // add game to availableGames
                availableGames[index] = game;
                ++index;
            }
        }
    }

    function findGamesForPlayer(
        address playerAddress
    ) public view returns (uint256[] memory) {
        return playerGames[playerAddress];
    }

    function play(uint256 gameID) external payable {
        //
        require(
            !hasActiveRoll[gameID],
            "game has active roll, wait to play until resolved"
        );
        require(
            _senderCanPlay(_msgSender(), gameID),
            "sender not authorized to play"
        );
        GameInfo memory game = games[gameID];
        if (isInGame[gameID][_msgSender()]) {
            // request roll if game is full otherwise nothing to do...
            require(
                game.players.length == game.gameSize,
                "Waiting for players to join, game not full."
            );
            gameRollIDs[gameID] = requestRoll(
                address(this),
                uint32(game.players.length),
                _die.values.length
            );
            gameIDsFromRollID[gameRollIDs[gameID]] = gameID;
            hasActiveRoll[gameID] = true;
        } else {
            // register for game if possible
            require(
                game.players.length < game.gameSize,
                "Cannot join game. Game is full."
            );
            if (!entryFeePaid[gameID][_msgSender()]) {
                require(msg.value >= entryFee, "minimum entry fee not sent");
                entryFeePaid[gameID][_msgSender()] = true;
            }
            _enterPlayer(gameID, _msgSender());
        }
    }

    function poolBalance(uint256 gameID) external view returns (uint256) {
        return _poolBalances[gameID];
    }

    // join game without rolling
    function joinGame(uint256 gameID) public payable {
        if (!entryFeePaid[gameID][_msgSender()]) {
            require(msg.value >= entryFee, "minimum entry fee not sent");
            entryFeePaid[gameID][_msgSender()] = true;
        }
        _enterPlayer(gameID, _msgSender());
    }

    // Handle DiceRoll roll delivered
    function rollDelivered(
        uint256 rollID,
        uint256[] memory diceValues
    ) internal override {
        uint256 gameID = gameIDsFromRollID[rollID];
        _updateGameFromRoll(diceValues, rollID);
        GameInfo memory game = games[gameID];
        if (game.complete && game.winner != address(0)) {
            _payoutPool(game);
        }
        hasActiveRoll[gameID] = false;
    }

    // Functions to override
    function _senderCanPlay(
        address /*sender*/,
        uint256 /*gameID*/
    ) internal virtual returns (bool) {
        return true;
    }

    function _updateGameFromRoll(
        uint256[] memory diceValues,
        uint256 gameID
    ) internal virtual {}

    // Internal
    function _enterPlayer(uint256 gameID, address playerAddress) internal {
        if (
            !isInGame[gameID][playerAddress] &&
            entryFeePaid[gameID][playerAddress]
        ) {
            GameInfo storage game = games[gameID];
            game.players.push(playerAddress);
            isInGame[gameID][playerAddress] = true;
            playerGames[playerAddress].push(gameID);
        }
    }

    function _payoutPool(GameInfo memory game) internal {
        // pay out balance of pool
        uint256 payoutAmount = _poolBalances[game.gameID];
        (bool sent, ) = game.winner.call{value: payoutAmount}("");
        require(sent, "Failed to pay pool");
        emit PoolPayout(game.winner, payoutAmount, block.timestamp);
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

// the base contract for multi-player example dice games
// Features:
// - multiple players join a game
// - once game is at capacity, any player can trigger a roll for the turn
// - turns can continue until win state is met (x number of turns or x points)
// - once win state is met, payout winner
