// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IMultiAttack} from "./IMultiAttack.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";

contract GameInstance {
    // enumerations
    Class public class;
    GamePhase public gamePhase;

    address challenger;
    address defender;

    MultiAttackToken MAT;
    MultiAttackNFT MAN;

    constructor(address _challenger, address _defender, MultiAttackToken _MAT, MultiAttackNFT _MAN) {
        challenger = _challenger;
        defender = _defender;
        MAT = _MAT;
        MAN = _MAN;
    }

    modifier onlyParticipants(address addr) {
        require(addr == challenger || addr == defender, "INVALID_SENDER");
    }

    function delegationRole(address _to) public onlyParticipants(msg.sender) {

    }
};