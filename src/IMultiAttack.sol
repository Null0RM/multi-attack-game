// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMultiAttack {
    enum GamePhase {
        readyPhase,
        bettingPhase,
        classPhase,
        warPhase,
        winPhase
    }

    enum Class {
        Warrior,
        Archer,
        Mage,
        Druid
    }

    
}