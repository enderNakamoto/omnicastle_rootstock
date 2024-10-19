// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

library Consts {
    uint256 constant INITIAL_ARMY_SIZE = 500;
    uint256 constant INITIAL_POINTS = 0;
    uint256 constant INITIAL_TURNS = 10;
    uint256 constant MAX_ATTACK = 2000;
    uint256 constant MAX_DEFENSE = 2000;
    uint256 constant TURNS_NEEDED_FOR_MOBILIZE = 1;
    uint256 constant TURNS_NEEDED_FOR_ATTACK = 3;
    uint256 constant TURNS_NEEDED_FOR_CHANGE_DEFENSE = 3;
    uint256 constant TURN_INTERVAL = 1 hours;
    uint256 constant ATTACK_COOLDOWN = 1 hours;
    uint256 constant POINTS_FOR_ATTACK_WIN = 100;
    uint256 constant POINTS_PER_TURN_FOR_KING = 10;
    uint256 constant MAX_TURNS = 100;

}