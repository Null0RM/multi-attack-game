// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IMultiAttack} from "./IMultiAttack.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";

contract GameInstance is IMultiAttack, Multicall {
    address GameManager;
    address winner;
    uint256 gameNum;
    // enumerations
    GamePhase public gamePhase;

    mapping(address => User) public players;
    mapping(Role => address) public playerAddr;

    MultiAttackToken MAT;
    MultiAttackNFT MAN;

    event winGame(address winnerAddr);

    error InvalidInput();

    constructor(address _challenger, address _defender, MultiAttackToken _MAT, MultiAttackNFT _MAN, uint256 gameId) {
        GameManager = msg.sender;

        players[_challenger].role = Role.challenger;
        players[_challenger].status = UserStatus.waiting;
        playerAddr[Role.challenger] = _challenger;

        players[_defender].role = Role.defender;
        players[_defender].status = UserStatus.waiting;
        playerAddr[Role.defender] = _defender;

        MAT = _MAT;
        MAN = _MAN;
        gameNum = gameId;
        gamePhase = GamePhase.readyPhase;
    }

    modifier onlyParticipants() {
        require(msg.sender == playerAddr[Role.challenger] || msg.sender == playerAddr[Role.defender], "INVALID_SENDER");
        _;
    }

    modifier onlyWarrior() {
        require(players[msg.sender].class == WarClass.Warrior, "YOU_ARE_NOT_WARRIOR");
        _;
    }

    modifier onlyArcher() {
        require(players[msg.sender].class == WarClass.Archer, "YOU_ARE_NOT_ARCHER");
        _;
    }

    modifier onlyMage() {
        require(players[msg.sender].class == WarClass.Mage, "YOU_ARE_NOT_MAGE");
        _;
    }

    modifier onlyDruid() {
        require(players[msg.sender].class == WarClass.Druid, "YOU_ARE_NOT_DRUID");
        _;
    }

    function Betting(uint256 bettingAmount, uint256 manaPointRate, uint256 healthPointRate) public {
        require(gamePhase >= GamePhase.readyPhase, "INCORRECT_PHASE"); // 게임 준비 단계 부터 베팅 가능
        require(gamePhase < GamePhase.winPhase, "INCORRECT_PHASE"); // 끝나기 전 까지만 베팅 가능
        require(bettingAmount >= 0.001 ether, "INSUFFICIENT_BETTING_AMOUNT");
        require(manaPointRate + healthPointRate == 100, "HP_AND_MP_SUMMATION_SHOULD_100");

        uint tmp;

        User memory player = players[msg.sender];

        if (player.HP_weight == 0) player.HP_weight = 100;
        if (player.MP_weight == 0) player.MP_weight = 100;
    
        // 가스 fee 감소를 위해 어셈블리로 작성 가능
        player.userBet += bettingAmount;
        bettingAmount /= 1e13;
        tmp = (bettingAmount * healthPointRate / 100);
        player.HP += tmp * player.HP_weight / 100;
        player.MP += (bettingAmount - tmp) * player.MP_weight / 100;

        players[msg.sender] = player;
        MAT.transferFrom(msg.sender, GameManager, bettingAmount);
    }
    /**
     * ################################### READY ######################################
     * ready phase
     * 전투를 준비하는 phase.
     */

    /**
     * 다른 컨트랙트 또는 EOA를 이용해 전투를 진행하고싶을 경우 이용하는 함수
     */
    function delegationRole(address _to) external onlyParticipants {
        if (msg.sender == playerAddr[Role.challenger]) {
            playerAddr[Role.challenger] = _to;
            players[_to] = players[msg.sender];
        } else {
            playerAddr[Role.defender] = _to;
            players[_to] = players[msg.sender];
        }
    }

    /**
     * 최초베팅 후, 게임 준비를 완료하는 함수
     */
    function setGame() external onlyParticipants {
        require(gamePhase == GamePhase.readyPhase, "NOT_READY_PAHSE");
        require(players[msg.sender].userBet >= 0.001 ether, "SET_AFTER_BET");

        players[msg.sender].status = UserStatus.ready;
        if (
            players[playerAddr[Role.challenger]].status == UserStatus.ready
                && players[playerAddr[Role.defender]].status == UserStatus.ready
        ) {
            gamePhase = GamePhase.classPhase;
        }
    }

    /**
     * ################################### CLASS_SELECTION ######################################
     */
    function selectClass(WarClass class) external onlyParticipants {
        require(gamePhase == GamePhase.classPhase, "NOT_CLASS_SELECTION_PHASE");
        User memory player = players[msg.sender];

        if (class == WarClass.Warrior) {
            player.class = WarClass.Warrior;
            player.status = UserStatus.war;
            player.HP_weight = 120;
            player.MP_weight = 100;
        } else if (class == WarClass.Archer) {
            player.class = WarClass.Archer;
            player.status = UserStatus.war;
            player.HP_weight = 90;
            player.MP_weight = 110;

        } else if (class == WarClass.Mage) {
            player.class = WarClass.Mage;
            player.status = UserStatus.war;
            player.HP_weight = 80;
            player.MP_weight = 120;
        } else if (class == WarClass.Druid) {
            player.class = WarClass.Druid;
            player.status = UserStatus.war;
            player.HP_weight = 140;
            player.MP_weight = 100;
        } else {
            revert InvalidInput();
        }
        players[msg.sender] = player;

        if (
            players[playerAddr[Role.challenger]].status == UserStatus.war
                && players[playerAddr[Role.defender]].status == UserStatus.war
        ) {
            gamePhase = GamePhase.warPhase;
        }
    }
    /**
     * ####################################### WAR #######################################
     */
    /**
     * ################ WARRIOR ################
     */

    function berserkSlash() external onlyParticipants onlyWarrior {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 20;
        uint damage = 40;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }
        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }
    function destructStab() external onlyParticipants onlyWarrior {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 30;
        uint damage = 50;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }
        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    function shieldBash() external onlyParticipants onlyWarrior {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 15;
        uint damage = 15;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    /**
     * ################ ARCHER ################
     */
    function piercingArrow() external onlyParticipants onlyArcher {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 25;
        uint damage = 50;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }
    function multiShot() external onlyParticipants onlyArcher {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 35;
        uint damage = 65;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }
    function explosiveShot() external onlyParticipants onlyArcher {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 30;
        uint damage = 60;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    /**
     * ################ MAGE ################
     */
    function fireBall() external onlyParticipants onlyMage {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 30;
        uint damage = 70;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }
    function heal() external onlyParticipants onlyMage {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 25;
        uint healAmount = 50;
        User memory player = players[msg.sender];
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        unchecked { // for avoid underflow revert
            player.HP += healAmount;
        }

        players[msg.sender] = player;
    }

    function lightningBolt() external onlyParticipants onlyMage {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 30;
        uint damage = 60;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    /**
     * ################ DRUID ################
     */
    function thornArmor() external onlyParticipants onlyDruid {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 15;
        uint damage = 25;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    function healingTouch() external onlyParticipants onlyDruid {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 25;
        uint healAmount = 50;
        User memory player = players[msg.sender];
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        unchecked { // for avoid underflow revert
            player.HP += healAmount;
        }

        players[msg.sender] = player;
    }

    function naturesWrath() external onlyParticipants onlyDruid {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        uint mana = 25;
        uint damage = 45;
        User memory player = players[msg.sender];
        User memory opponent;
        require(player.MP >= mana, "NOT_ENOUGH_MANA");
        
        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        unchecked { // for avoid underflow revert
            opponent.HP -= damage;
        }

        players[msg.sender] = player;
        if (msg.sender == playerAddr[Role.challenger])
            players[playerAddr[Role.defender]] = opponent;
        else 
            players[playerAddr[Role.challenger]] = opponent;
    }

    function declareVictory() external onlyParticipants returns (address) {
        require(gamePhase == GamePhase.warPhase, "INCORRECT_PHASE");
        User memory opponent;

        if (msg.sender == playerAddr[Role.challenger])
            opponent = players[playerAddr[Role.defender]];
        else 
            opponent = players[playerAddr[Role.challenger]];
        
        require(opponent.HP <= 0, "OPPONENT_NOT_DEAD");
        winner = msg.sender;

        emit winGame(winner);
        return winner;
    }
    /**
     * ####################################### WIN_PAHSE #######################################
     */
    function winNFTAndTakeWarToken() external onlyParticipants {
        require(gamePhase == GamePhase.winPhase, "INCORRECT_PHASE");
        require(msg.sender == winner, "YOU_ARE_NOT_WINNER");
        address loser;
        uint256 loserBet;
        uint256 winnerBet;
        uint256 prize;

        if (msg.sender == playerAddr[Role.challenger])
            loser = playerAddr[Role.defender];
        else 
            loser = playerAddr[Role.challenger];

        winnerBet = players[msg.sender].userBet;
        loserBet = players[loser].userBet;
        prize = (winnerBet + loserBet) * 90 / 100;
        MAT.transfer(msg.sender, prize);
        MAN.mint(msg.sender);
    }
}
