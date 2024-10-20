// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import "./Consts.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract KingOfTheCastle is AccessControl {

    enum Weather {
        CLEAR,
        CLOUDS,
        SNOW,
        RAIN,
        DRIZZLE,
        THUNDERSTORM
    }
	
    struct Army {
        uint256 archers;
        uint256 infantry;
        uint256 cavalry;
    }

    struct Castle {
        Army defense;
        address currentKing;
        uint256 lastKingChangedAt;
    }

    struct Player {
        string generalName;
        Army attackingArmy;
        uint256 points;
        uint256 turns;
    }

    struct GameState {
        mapping(address => Player) players;
        uint256 numberOfAttacks;
        Castle castle;
        Weather currentWeather;
    }

    GameState public gameState;
    uint256 public lastTickTock;
    address public immutable owner;
    address[] public playerAddresses;

    bytes32 public constant WEATHERMAN_ROLE = keccak256("WEATHERMAN_ROLE");

    event PlayerJoined(address player, string generalName);
    event ArmyMobilized(address player, uint256 archers, uint256 infantry, uint256 cavalry);
    event AttackLaunched(address attacker, address defender, bool success);
    event DefenseChanged(address king, uint256 archers, uint256 infantry, uint256 cavalry);
    event TurnAdded(address player, uint256 newTurns);
    event WeatherChanged(Weather newWeather);


    constructor() {
        owner = msg.sender;
        lastTickTock = block.timestamp;
        initializeGame();

        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(WEATHERMAN_ROLE, msg.sender);
    }

    function initializeGame() private {
        gameState.castle.defense = Army(Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE);
        gameState.castle.currentKing = owner;
        gameState.castle.lastKingChangedAt = block.timestamp;
        gameState.currentWeather = Weather.CLEAR;

        // Initialize the owner as the first player
        gameState.players[owner] = Player("Castle Owner", Army(Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE), Consts.INITIAL_POINTS, Consts.INITIAL_TURNS);
        playerAddresses.push(owner);
    }

    // Public functions for the game

    function joinGame(string memory generalName) external {
        require(bytes(gameState.players[msg.sender].generalName).length == 0, "Player has already joined");
        gameState.players[msg.sender] = Player(
            generalName,
            Army(Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE),
            Consts.INITIAL_POINTS,
            Consts.INITIAL_TURNS
        );
        playerAddresses.push(msg.sender);
        emit PlayerJoined(msg.sender, generalName);
    }

    function mobilize(uint256 archers, uint256 infantry, uint256 cavalry) external {
        Player storage player = gameState.players[msg.sender];
        require(player.turns > 0, "Player has not joined the game");
        require(player.turns >= Consts.TURNS_NEEDED_FOR_MOBILIZE, "Not enough turns");
        require(archers + infantry + cavalry <= Consts.MAX_ATTACK, "Army size exceeds maximum");

        player.attackingArmy = Army(archers, infantry, cavalry);
        player.turns -= Consts.TURNS_NEEDED_FOR_MOBILIZE;

        emit ArmyMobilized(msg.sender, archers, infantry, cavalry);
    }

    // function setWeather(Weather newWeather) external onlyRole(WEATHERMAN_ROLE) {
    //     gameState.currentWeather = newWeather;
    //     emit WeatherChanged(newWeather);
    // }

    function setWeather(Weather newWeather) external {
        gameState.currentWeather = newWeather;
        emit WeatherChanged(newWeather);
    }

    function attack() external {
        Player storage attacker = gameState.players[msg.sender];
        require(attacker.turns > 0, "Attacker has not joined the game");
        require(msg.sender != gameState.castle.currentKing, "Current king cannot attack");
        require(attacker.turns >= Consts.TURNS_NEEDED_FOR_ATTACK, "Not enough turns");
        require(block.timestamp >= gameState.castle.lastKingChangedAt + Consts.ATTACK_COOLDOWN, "Castle is under protection");

        bool attackSuccess = calculateBattleOutcome(attacker.attackingArmy, gameState.castle.defense);

        if (attackSuccess) {
            gameState.castle.currentKing = msg.sender;
            gameState.castle.lastKingChangedAt = block.timestamp;
            gameState.castle.defense = Army(Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE);
            attacker.points += Consts.POINTS_FOR_ATTACK_WIN;
        }

        attacker.turns -= Consts.TURNS_NEEDED_FOR_ATTACK;
        gameState.numberOfAttacks++;

        emit AttackLaunched(msg.sender, gameState.castle.currentKing, attackSuccess);
    }

    function changeDefense(uint256 archers, uint256 infantry, uint256 cavalry) external {
        require(msg.sender == gameState.castle.currentKing, "Only the current king can change defense");
        Player storage king = gameState.players[msg.sender];
        require(king.turns >= Consts.TURNS_NEEDED_FOR_CHANGE_DEFENSE, "Not enough turns");
        require(archers + infantry + cavalry <= Consts.MAX_DEFENSE, "Defense size exceeds maximum");

        gameState.castle.defense = Army(archers, infantry, cavalry);
        king.turns -= Consts.TURNS_NEEDED_FOR_CHANGE_DEFENSE;

        emit DefenseChanged(msg.sender, archers, infantry, cavalry);
    }

    function tickTock() external {
        require(block.timestamp >= lastTickTock + Consts.TURN_INTERVAL, "Too soon to call tickTock");
        
        for (uint i = 0; i < playerAddresses.length; i++) {
            Player storage player = gameState.players[playerAddresses[i]];
            if (player.turns < Consts.MAX_TURNS) {
                player.turns++;
                emit TurnAdded(playerAddresses[i], player.turns);
            }
        }

        if (gameState.players[gameState.castle.currentKing].points < type(uint256).max) {
            gameState.players[gameState.castle.currentKing].points += Consts.POINTS_PER_TURN_FOR_KING;
        }

        lastTickTock = block.timestamp;
    }

    // view functions for the game

    function getPlayerCount() public view returns (uint256) {
        return playerAddresses.length;
    }

    function getCastle() public view returns (Castle memory) {
        return gameState.castle;
    }

    function getPlayer(address playerAddress) public view returns (Player memory) {
        return gameState.players[playerAddress];
    }

    function getCurrentWeather() public view returns (Weather) {
        return gameState.currentWeather;
    }


    // Internal functions for the game
    function calculateBattleOutcome(Army memory attackingArmy, Army memory defendingArmy) private view returns (bool) {
        uint256 attackingPower = calculateAdjustedArmyPower(attackingArmy, gameState.currentWeather);
        uint256 defendingPower = calculateAdjustedArmyPower(defendingArmy, gameState.currentWeather);
        return attackingPower > defendingPower;
    }

    // weather effects
    function calculateAdjustedArmyPower(Army memory army, Weather weather) private pure returns (uint256) {
        uint256 archerPower = army.archers;
        uint256 infantryPower = army.infantry;
        uint256 cavalryPower = army.cavalry;

        if (weather == Weather.CLOUDS) {
            archerPower = archerPower * Consts.ADVANTAGE  / 100;
            cavalryPower = cavalryPower * Consts.EXTREME_ADVANTAGE / 100;
        } else if (weather == Weather.SNOW) {
            archerPower = archerPower * Consts.ADVANTAGE / 100;
            infantryPower = infantryPower * Consts.ADVANTAGE / 100;
            cavalryPower = cavalryPower * Consts.DISADVANTAGE / 100;
        } else if (weather == Weather.RAIN) {
            archerPower = archerPower * Consts.DISADVANTAGE / 100;
            infantryPower = infantryPower * Consts.ADVANTAGE / 100;
            cavalryPower = cavalryPower * Consts.DISADVANTAGE / 100;
        } else if (weather == Weather.DRIZZLE) {
            archerPower = archerPower * Consts.ADVANTAGE / 100;
            infantryPower = infantryPower * Consts.ADVANTAGE / 100;
        } else if (weather == Weather.THUNDERSTORM) {
            archerPower = archerPower * Consts.DISADVANTAGE / 100;
            infantryPower = infantryPower * Consts.EXTREME_ADVANTAGE / 100;
            cavalryPower = cavalryPower * Consts.EXTREME_DISADVANTAGE / 100;
        }
        // Weather.CLEAR has no effect

        return archerPower + infantryPower + cavalryPower;
    }                      


}