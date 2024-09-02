// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Multicall} from "@openzeppelin/contracts/utils/Multicall.sol";
import {IMultiAttack} from "./IMultiAttack.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";

contract GameInstance is IMultiAttack, Multicall {
    address GameManager;

    // enumerations
    GamePhase public gamePhase;

    mapping(address => User) public players;
    mapping(Role => address) public playerAddr;

    MultiAttackToken MAT;
    MultiAttackNFT MAN;

    error InvalidInput();

    constructor(address _challenger, address _defender, MultiAttackToken _MAT, MultiAttackNFT _MAN) {
        GameManager = msg.sender;

        players[_challenger].role = Role.challenger;
        players[_challenger].status = UserStatus.waiting;
        playerAddr[Role.challenger] = _challenger;

        players[_defender].role = Role.defender;
        players[_defender].status = UserStatus.waiting;
        playerAddr[Role.defender] = _defender;

        MAT = _MAT;
        MAN = _MAN;
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
        
        User memory player = players[msg.sender];
        
        // 가스 fee 감소를 위해 어셈블리로 작성 가능
        bettingAmount /= 1e13;
        player.userBet += bettingAmount;
        player.HP += bettingAmount * healthPointRate / 100;
        player.MP += bettingAmount - player.HP;

        players[msg.sender] = player;
        MAT.transferFrom(msg.sender, GameManager, bettingAmount);
    }
    /**
    ################################### READY ######################################
     * ready phase
     * 전투를 준비하는 phase.
     */

    /**
     * 다른 컨트랙트 또는 EOA를 이용해 전투를 진행하고싶을 경우 이용하는 함수
     */
    function delegationRole(address _to) external onlyParticipants() {
        require(gamePhase < GamePhase.winPhase, "INCORRECT_PAHSE");
        if (msg.sender == playerAddr[Role.challenger])
        {
            playerAddr[Role.challenger] = _to;
            players[_to] = players[msg.sender];
        }
        else 
        {
            playerAddr[Role.defender] = _to;
            players[_to] = players[msg.sender];
        }        
    }
    
    /**
     * 최초베팅 후, 게임 준비를 완료하는 함수
     */
    function setGame() external onlyParticipants() {
        require(gamePhase == GamePhase.readyPhase, "NOT_READY_PAHSE");
        require(players[msg.sender].userBet >= 0.001 ether, "SET_AFTER_BET");
        
        players[msg.sender].status = UserStatus.ready;
        if (players[playerAddr[Role.challenger]].status == UserStatus.ready 
            && players[playerAddr[Role.defender]].status == UserStatus.ready)
        {
            gamePhase = GamePhase.classPhase;
        }
    }

    
    /** 
    ################################### CLASS_SELECTION ######################################
    */
    function selectClass(WarClass class) external onlyParticipants() {
        require(gamePhase == GamePhase.classPhase, "NOT_CLASS_SELECTION_PAHSE");
        if (class == WarClass.Warrior) {}
        else if (class == WarClass.Archer) {}
        else if (class == WarClass.Mage) {} 
        else if (class == WarClass.Druid) {}
        else {
            revert InvalidInput();
        }

        gamePhase = GamePhase.warPhase;
    }
    /** 
    ####################################### WAR #######################################
    */
    /** 
    ################ WARRIOR ################
    */
    function berserkSlash() external onlyParticipants onlyWarrior {}
    function whirlWind() external onlyParticipants onlyWarrior {}
    function ShieldBash() external onlyParticipants onlyWarrior {} 

    /** 
    ################ ARCHER ################
    */
    function piercingArrow() external  onlyParticipants onlyArcher {}
    function multiShot() external onlyParticipants onlyArcher {}
    function ExplosiveShot() external onlyParticipants onlyArcher {}

    /** 
    ################ MAGE ################
    */
    function fireBall()  external onlyParticipants onlyMage {}
    function heal() external onlyParticipants onlyMage {}
    function LightningBolt() external onlyParticipants onlyMage {}

    /** 
    ################ DRUID ################
    */
    function ThornArmor() external onlyParticipants onlyDruid {}
    function healingTouch() external onlyParticipants onlyDruid {}
    function naturesWrath() external onlyParticipants onlyDruid {}  

    function declareVictory() external onlyParticipants {} 
    /** 
    ####################################### WIN_PAHSE #######################################
    */    
    function winNFTAndTakeWarToken() external onlyParticipants {}
}