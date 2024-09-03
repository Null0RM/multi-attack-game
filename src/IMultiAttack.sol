// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IMultiAttack {
    enum GamePhase {
        readyPhase,
        classPhase,
        warPhase,
        winPhase
    }

    enum WarClass {
        Warrior,
        Archer,
        Mage,
        Druid
    }

    enum UserStatus {
        waiting,
        ready,
        war,
        win
    }

    enum Role {
        challenger,
        defender
    }

    struct User {
        Role role;
        WarClass class;
        UserStatus status; // waiting, ready, war
        uint256 HP;
        uint256 HP_weight;
        uint256 MP;
        uint256 MP_weight;
        uint256 userBet;
        uint256 chargeNum; // 충전 횟수
    }
}
