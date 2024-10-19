// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../contracts/KingOfTheCastle.sol";
import "../contracts/Consts.sol";

contract KingOfTheCastleTest is Test {
    KingOfTheCastle public game;
    address public owner;
    address public player1;
    address public player2;
    address public attacker;


    function setUp() public {
        owner = address(this);
        player1 = address(0x1);
        player2 = address(0x2);
        attacker = address(0x3);
        game = new KingOfTheCastle();
    }

    function testDeployment() public view {
        assertEq(game.owner(), owner, "Owner should be set to the deployer");
    }

    function testInitialization() public view {
        // Test castle state
        KingOfTheCastle.Castle memory castle = game.getCastle();

        assertEq(castle.defense.archers, Consts.INITIAL_ARMY_SIZE, "Initial castle archers should be set correctly");
        assertEq(castle.defense.infantry, Consts.INITIAL_ARMY_SIZE, "Initial castle infantry should be set correctly");
        assertEq(castle.defense.cavalry, Consts.INITIAL_ARMY_SIZE, "Initial castle cavalry should be set correctly");
        assertEq(castle.currentKing, owner, "Initial king should be the contract owner");
        assertEq(castle.lastKingChangedAt, block.timestamp, "Last king changed timestamp should be set to deployment time");

        // Test owner's player state
        KingOfTheCastle.Player memory ownerPlayer = game.getPlayer(owner);

        assertEq(ownerPlayer.generalName, "Castle Owner", "Owner's general name should be set correctly");
        assertEq(ownerPlayer.attackingArmy.archers, Consts.INITIAL_ARMY_SIZE, "Owner's initial archers should be set correctly");
        assertEq(ownerPlayer.attackingArmy.infantry, Consts.INITIAL_ARMY_SIZE, "Owner's initial infantry should be set correctly");
        assertEq(ownerPlayer.attackingArmy.cavalry, Consts.INITIAL_ARMY_SIZE, "Owner's initial cavalry should be set correctly");
        assertEq(ownerPlayer.points, Consts.INITIAL_POINTS, "Owner's initial points should be set correctly");
        assertEq(ownerPlayer.turns, Consts.INITIAL_TURNS, "Owner's initial turns should be set correctly");

        assertEq(game.getPlayerCount(), 1, "Initial player count should be 1");
    }

    function testJoinGame() public {
        address newPlayer = address(0x1);
        vm.prank(newPlayer);
        game.joinGame("New General");

        KingOfTheCastle.Player memory player = game.getPlayer(newPlayer);

        assertEq(player.generalName, "New General", "New player's general name should be set correctly");
        assertEq(player.attackingArmy.archers, Consts.INITIAL_ARMY_SIZE, "New player's initial archers should be set correctly");
        assertEq(player.attackingArmy.infantry, Consts.INITIAL_ARMY_SIZE, "New player's initial infantry should be set correctly");
        assertEq(player.attackingArmy.cavalry, Consts.INITIAL_ARMY_SIZE, "New player's initial cavalry should be set correctly");
        assertEq(player.points, Consts.INITIAL_POINTS, "New player's initial points should be set correctly");
        assertEq(player.turns, Consts.INITIAL_TURNS, "New player's initial turns should be set correctly");

        assertEq(game.getPlayerCount(), 2, "Player count should be 2 after a new player joins");
    }

    function testMobilize() public {
        uint256 archers = 50;
        uint256 infantry = 30;
        uint256 cavalry = 20;

        game.mobilize(archers, infantry, cavalry);

        KingOfTheCastle.Player memory player = game.getPlayer(owner);

        assertEq(player.attackingArmy.archers, archers, "Archers should be mobilized correctly");
        assertEq(player.attackingArmy.infantry, infantry, "Infantry should be mobilized correctly");
        assertEq(player.attackingArmy.cavalry, cavalry, "Cavalry should be mobilized correctly");
        assertEq(player.turns, Consts.INITIAL_TURNS - Consts.TURNS_NEEDED_FOR_MOBILIZE, "Turns should be deducted after mobilization");
    }

    function testTickTock() public {        
        vm.prank(player1);
        game.joinGame("General One");
        vm.prank(player2);
        game.joinGame("General Two");

        // Set initial turns for players
        // Note: We can't set these directly now, so we'll have to work with the initial state
        
        // Record initial state
        KingOfTheCastle.Player memory ownerPlayerBefore = game.getPlayer(owner);
        KingOfTheCastle.Player memory player1DataBefore = game.getPlayer(player1);
        KingOfTheCastle.Player memory player2DataBefore = game.getPlayer(player2);

        // Advance time by 1 hour
        vm.warp(block.timestamp + 1 hours);

        // Call tickTock
        game.tickTock();

        // Check results
        KingOfTheCastle.Player memory ownerPlayerAfter = game.getPlayer(owner);
        KingOfTheCastle.Player memory player1DataAfter = game.getPlayer(player1);
        KingOfTheCastle.Player memory player2DataAfter = game.getPlayer(player2);

        // Check turns
        assertEq(ownerPlayerAfter.turns, ownerPlayerBefore.turns + 1, "Owner's turns should have increased by 1");
        assertEq(player1DataAfter.turns, player1DataBefore.turns + 1, "Player1's turns should have increased by 1");
        assertEq(player2DataAfter.turns, player2DataBefore.turns + 1, "Player2's turns should have increased by 1");

        // Check points for the king (owner)
        assertEq(ownerPlayerAfter.points, ownerPlayerBefore.points + Consts.POINTS_PER_TURN_FOR_KING, "Owner's points should have increased");

        // Try to call tickTock again immediately (should fail)
        vm.expectRevert("Too soon to call tickTock");
        game.tickTock();

        // Advance time by 1 hour again
        vm.warp(block.timestamp + 1 hours);

        // Call tickTock again (should succeed)
        game.tickTock();

        // Check results again
        ownerPlayerAfter = game.getPlayer(owner);
        player1DataAfter = game.getPlayer(player1);
        player2DataAfter = game.getPlayer(player2);

        // Check turns
        assertEq(ownerPlayerAfter.turns, ownerPlayerBefore.turns + 2, "Owner's turns should have increased by 2");
        assertEq(player1DataAfter.turns, player1DataBefore.turns + 2, "Player1's turns should have increased by 2");
        assertEq(player2DataAfter.turns, player2DataBefore.turns + 2, "Player2's turns should have increased by 2");

        // Check points for the king (owner)
        assertEq(ownerPlayerAfter.points, ownerPlayerBefore.points + 2 * Consts.POINTS_PER_TURN_FOR_KING, "Owner's points should have increased twice");
    }

    function testTickTockTooSoon() public {
        // Advance time by 1 hour from deployment
        vm.warp(block.timestamp + 1 hours);

        // Call tickTock
        game.tickTock();

        // Try to call tickTock again immediately (should fail)
        vm.expectRevert("Too soon to call tickTock");
        game.tickTock();

        // Advance time by 59 minutes
        vm.warp(block.timestamp + 59 minutes);

        // Try to call tickTock again (should still fail)
        vm.expectRevert("Too soon to call tickTock");
        game.tickTock();

        // Advance time by 1 more minute
        vm.warp(block.timestamp + 1 minutes);

        // Call tickTock again (should succeed)
        game.tickTock();
    }

    function testChangeDefenseSuccess() public {
        uint256 newArchers = 200;
        uint256 newInfantry = 300;
        uint256 newCavalry = 100;

        // Ensure we have enough turns
        vm.warp(block.timestamp + 1 hours);
        game.tickTock();

        // Change defense
        game.changeDefense(newArchers, newInfantry, newCavalry);

        // Check if defense was updated correctly
        KingOfTheCastle.Castle memory castle = game.getCastle();
        assertEq(castle.defense.archers, newArchers, "Archers should be updated");
        assertEq(castle.defense.infantry, newInfantry, "Infantry should be updated");
        assertEq(castle.defense.cavalry, newCavalry, "Cavalry should be updated");

        // Check if turns were deducted
        KingOfTheCastle.Player memory player = game.getPlayer(owner);
        assertEq(player.turns, Consts.INITIAL_TURNS + 1 - Consts.TURNS_NEEDED_FOR_CHANGE_DEFENSE, "Turns should be deducted");
    }

    function testChangeDefenseFailureNotKing() public {
        address newPlayer = address(0x1);
        
        // Add a new player
        vm.prank(newPlayer);
        game.joinGame("New General");

        // Ensure we have enough turns
        vm.warp(block.timestamp + 1 hours);
        game.tickTock();

        // Try to change defense as non-king player
        vm.prank(newPlayer);
        vm.expectRevert("Only the current king can change defense");
        game.changeDefense(100, 100, 100);

        // Verify defense hasn't changed
        KingOfTheCastle.Castle memory castle = game.getCastle();
        assertEq(castle.defense.archers, Consts.INITIAL_ARMY_SIZE, "Archers should not change");
        assertEq(castle.defense.infantry, Consts.INITIAL_ARMY_SIZE, "Infantry should not change");
        assertEq(castle.defense.cavalry, Consts.INITIAL_ARMY_SIZE, "Cavalry should not change");
    }

    function testChangeDefenseFailureTooManyTroops() public {
        uint256 excessiveTroops = Consts.MAX_DEFENSE / 2 + 1;

        // Ensure we have enough turns
        vm.warp(block.timestamp + 1 hours);
        game.tickTock();

        // Try to change defense with too many troops
        vm.expectRevert("Defense size exceeds maximum");
        game.changeDefense(excessiveTroops, excessiveTroops, excessiveTroops);

        // Verify defense hasn't changed
        KingOfTheCastle.Castle memory castle = game.getCastle();
        assertEq(castle.defense.archers, Consts.INITIAL_ARMY_SIZE, "Archers should not change");
        assertEq(castle.defense.infantry, Consts.INITIAL_ARMY_SIZE, "Infantry should not change");
        assertEq(castle.defense.cavalry, Consts.INITIAL_ARMY_SIZE, "Cavalry should not change");
    }

    function testInitialWeather() public view {
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.CLEAR), "Initial weather should be CLEAR");
    }

    function testChangeWeatherAsOwner() public {
        game.setWeather(KingOfTheCastle.Weather.RAIN);
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.RAIN), "Weather should be changed to RAIN");
    }

    function testChangeWeatherAsNonOwner() public {
        vm.prank(player1);
        vm.expectRevert();
        game.setWeather(KingOfTheCastle.Weather.SNOW);
    }

    function testChangeWeatherMultipleTimes() public {
        game.setWeather(KingOfTheCastle.Weather.CLOUDS);
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.CLOUDS), "Weather should be changed to CLOUDS");

        game.setWeather(KingOfTheCastle.Weather.THUNDERSTORM);
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.THUNDERSTORM), "Weather should be changed to THUNDERSTORM");

        game.setWeather(KingOfTheCastle.Weather.CLEAR);
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.CLEAR), "Weather should be changed back to CLEAR");
    }

    function testWeatherChangeEvent() public {
        vm.expectEmit(true, true, true, true);
        emit KingOfTheCastle.WeatherChanged(KingOfTheCastle.Weather.DRIZZLE);
        game.setWeather(KingOfTheCastle.Weather.DRIZZLE);
    }

    function testGrantWeathermanRole() public {
        // Grant WEATHERMAN_ROLE to player1
        game.grantRole(game.WEATHERMAN_ROLE(), player1);

        // player1 should now be able to change the weather
        vm.prank(player1);
        game.setWeather(KingOfTheCastle.Weather.SNOW);
        assertEq(uint(game.getCurrentWeather()), uint(KingOfTheCastle.Weather.SNOW), "Weather should be changed to SNOW by player1");
    }

    function testRevokeWeathermanRole() public {
        // Grant WEATHERMAN_ROLE to player1
        game.grantRole(game.WEATHERMAN_ROLE(), player1);

        // Revoke WEATHERMAN_ROLE from player1
        game.revokeRole(game.WEATHERMAN_ROLE(), player1);

        // player1 should no longer be able to change the weather
        vm.prank(player1);
        vm.expectRevert();
        game.setWeather(KingOfTheCastle.Weather.RAIN);
    }

    // Battle tests 
    function testBattleInClearWeather() public {
        game.setWeather(KingOfTheCastle.Weather.CLEAR);
        
        // Equal forces, defender should win
        _setupAndAssertBattle(500, 500, 500, 500, 500, 500, false);
        
        // Attacker slightly stronger, should win
        _setupAndAssertBattle(500, 500, 500, 501, 501, 501, true);
    }

    function testBattleInCloudyWeather() public {
        game.setWeather(KingOfTheCastle.Weather.CLOUDS);
        
        // Equal forces, attacker should win due to archer and cavalry advantage
        _setupAndAssertBattle(500, 500, 500, 500, 500, 500, true);
        
        // Defender slightly stronger, but attacker still wins due to weather
        _setupAndAssertBattle(510, 510, 510, 500, 500, 500, true);
        
        // Defender much stronger, should still win despite weather
        _setupAndAssertBattle(600, 600, 600, 500, 500, 500, false);
    }

    function testBattleInSnowWeather() public {
        game.setWeather(KingOfTheCastle.Weather.SNOW);
        
        // Equal forces, attacker should win due to archer and infantry advantage
        _setupAndAssertBattle(500, 500, 500, 500, 500, 500, true);
        
        // Attacker with more cavalry, but still loses due to snow disadvantage
        _setupAndAssertBattle(500, 500, 500, 450, 450, 650, false);
        
        // Defender with more cavalry, loses due to snow disadvantage
        _setupAndAssertBattle(450, 450, 650, 500, 500, 500, true);
    }

    function testBattleInRainWeather() public {
        game.setWeather(KingOfTheCastle.Weather.RAIN);
        
        // Equal forces, slight advantage to infantry-heavy army
        _setupAndAssertBattle(500, 500, 500, 450, 600, 450, true);
        
        // Archer and cavalry heavy army loses to infantry heavy army
        _setupAndAssertBattle(600, 400, 600, 400, 800, 400, true);
    }

    function testBattleInDrizzleWeather() public {
        game.setWeather(KingOfTheCastle.Weather.DRIZZLE);
        
        // Equal forces, attacker wins due to archer and infantry advantage
        _setupAndAssertBattle(500, 500, 500, 500, 500, 500, true);
        
        // Defender with more cavalry, but loses due to no advantage in drizzle
        _setupAndAssertBattle(450, 450, 650, 550, 550, 450, true);
    }

    function testBattleInThunderstormWeather() public {
        game.setWeather(KingOfTheCastle.Weather.THUNDERSTORM);
        
        // Equal forces, infantry-heavy army wins
        _setupAndAssertBattle(500, 500, 500, 400, 700, 400, true);
        
        // Extreme case: all cavalry vs all infantry
        _setupAndAssertBattle(0, 0, 1500, 0, 1000, 0, true);
        
        // Balanced army vs infantry-heavy army
        _setupAndAssertBattle(500, 500, 500, 300, 900, 300, true);
    }

    function testEdgeCaseBattles() public {
        // Test with minimum possible armies
        game.setWeather(KingOfTheCastle.Weather.CLEAR);
        _setupAndAssertBattle(1, 1, 1, 2, 2, 2, true);

        // Test with maximum possible armies (respecting MAX_DEFENSE and MAX_ATTACK)
        game.setWeather(KingOfTheCastle.Weather.CLEAR);
        _setupAndAssertBattle(500, 500, 500, 667, 667, 666, true);

        // Test where weather effect just barely tips the balance
        game.setWeather(KingOfTheCastle.Weather.CLOUDS);
        _setupAndAssertBattle(500, 500, 500, 455, 500, 455, true);
    }

    // Helper function to set up a battle scenario and assert the outcome
        function _setupAndAssertBattle(
        uint256 defenseArchers, 
        uint256 defenseInfantry, 
        uint256 defenseCavalry,
        uint256 attackArchers,
        uint256 attackInfantry,
        uint256 attackCavalry,
        bool expectedAttackerVictory
    ) private {
        require(defenseArchers + defenseInfantry + defenseCavalry <= Consts.MAX_DEFENSE, "Defense exceeds MAX_DEFENSE");
        require(attackArchers + attackInfantry + attackCavalry <= Consts.MAX_ATTACK, "Attack exceeds MAX_ATTACK");

        // Set up defender (owner)
        game.changeDefense(defenseArchers, defenseInfantry, defenseCavalry);

        // Advance time to bypass the attack cooldown
        vm.warp(block.timestamp + Consts.ATTACK_COOLDOWN + 1);

        // Set up attacker
        vm.startPrank(attacker);
        game.joinGame("Attacker");
        game.mobilize(attackArchers, attackInfantry, attackCavalry);
        game.attack();
        vm.stopPrank();

        // Assert the battle outcome
        if (expectedAttackerVictory) {
            assertEq(game.getCastle().currentKing, attacker, "Attacker should have won the battle");
        } else {
            assertEq(game.getCastle().currentKing, owner, "Defender should have won the battle");
        }

        // Reset the game state for the next test
        if (game.getCastle().currentKing != owner) {
            vm.prank(attacker);
            game.changeDefense(Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE, Consts.INITIAL_ARMY_SIZE);
        }
        game.tickTock(); // Add turns
        vm.warp(block.timestamp + Consts.TURN_INTERVAL + 1); // Advance time for tickTock
    }
}