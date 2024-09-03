// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import {console} from "forge-std/console.sol";
import "../src/IMultiAttack.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {MultiAttackToken} from "../src/MAT.sol";
import {MultiAttackNFT} from "../src/MAN.sol";
import {MultiAttackV1} from "../src/MultiAttackV1.sol";
import {MultiAttackProxy} from "../src/MultiAttackProxy.sol";
import {GameInstance} from "../src/GameInstance.sol";

contract TestMultiAttack is Test, IMultiAttack {
    bool suc;
    bytes data;

    MultiAttackToken MAT;
    MultiAttackNFT MAN;
    MultiAttackProxy proxy;
    MultiAttackV1 v1;

    address user1;
    address user2;
    address user3;
    address user4;

    function setUp() external {
        user1 = address(0x1);
        user2 = address(0x2);
        user3 = address(0x3);
        user4 = address(0x4);

        MAT = new MultiAttackToken();
        MAN = new MultiAttackNFT();
        v1 = new MultiAttackV1();
        proxy = new MultiAttackProxy(address(v1), address(MAT), address(MAN));

        MAT.registerProxy(address(proxy));
        MAN.registerProxy(address(proxy));

        vm.deal(address(this), 1000000 ether);
        vm.deal(user1, 1000 ether);
        vm.deal(user2, 1000 ether);
        vm.deal(user3, 1000 ether);
        vm.deal(address(proxy), 1000 ether);

        MAT.mint{value: 100000 ether}();

        vm.startPrank(user1);
        MAT.mint{value: 1000 ether}();

        vm.startPrank(user2);
        MAT.mint{value: 1000 ether}();

        vm.stopPrank();
    }

    function loggingPlayersStat(GameInstance game) public view {
        User memory p1 = game.getPlayerStat(Role.challenger);
        console.log("_____USER1_STAT_____");
        console.log("class:", uint(p1.class));
        console.log("HP:", p1.HP);
        console.log("HP_WEIGHT:", p1.HP_weight);
        console.log("MP:", p1.MP);
        console.log("MP_WEIGHT:", p1.MP_weight);
        console.log("ROLE:", uint(p1.role));
        console.log("game status:", uint(p1.status));
        console.log("bet Amount:", p1.userBet);

        User memory p2 = game.getPlayerStat(Role.defender);
        console.log("_____USER2_STAT_____");
        console.log("class:", uint(p2.class));
        console.log("HP:", p2.HP);
        console.log("HP_WEIGHT:", p2.HP_weight);
        console.log("MP:", p2.MP);
        console.log("MP_WEIGHT:", p2.MP_weight);
        console.log("ROLE:", uint(p2.role));
        console.log("game status:", uint(p2.status));
        console.log("bet Amount:", p2.userBet);
    }

    function testContractUpgradable() public {
        // 업그레이드를 해도 스토리지가 잘 유지되는지 확인
        (suc,) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "hello"));
        assertEq(suc, true);

        (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.gameNum.selector));
        assertEq(data, abi.encode(1));

        MultiAttackV1 v2 = new MultiAttackV1();
        (suc,) = address(proxy).call(abi.encodeWithSelector(v1.upgradeToAndCall.selector, address(v2), ""));
        assertEq(suc, true);

        (suc, data) = address(proxy).call(abi.encodeWithSelector(v2.gameNum.selector));
        assertEq(data, abi.encode(1));
    }

    function testEmergencyStop() public {
        (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.pause.selector));
        assertEq(suc, true);
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, false);
        }
    }

    function testInviteAndBetAndSet() public {
        GameInstance game;
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            assertEq(user2.balance, 1); // 1 ether와 함께 msg.data를 받음
            game = GameInstance(abi.decode(data, (address)));

            game.Betting(0.001 ether, 50, 50);
            game.setGame();
        }
        vm.stopPrank();

        vm.startPrank(user2);
        {
            game.Betting(0.001 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();

        assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase)); // class phase까지 잘 넘어갔는지 체크
    }

    function testInviteAndBetAndSetAndSelectClass() public {
        GameInstance game;
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.001 ether, 50, 50);
            game.setGame();
        }
        vm.stopPrank();

        vm.startPrank(user2);
        {
            game.Betting(0.001 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
        }

        assertEq(uint256(game.gamePhase()), uint256(GamePhase.warPhase));
    }

    function testInvalidUserCannotPlayGame() public {
        GameInstance game;
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.001 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user3);
        {
            vm.expectRevert("INVALID_SENDER");
            game.Betting(0.001 ether, 60, 40);
            vm.expectRevert("INVALID_SENDER");
            game.setGame();
        }
        vm.stopPrank();
        assertEq(uint256(game.gamePhase()), uint256(GamePhase.readyPhase));
        vm.startPrank(user2);
        {
            game.Betting(0.001 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
    }

    function testDelegationRole() public {
        GameInstance game;
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.001 ether, 50, 50);
            game.setGame();
        }
        vm.stopPrank();

        vm.startPrank(user2);
        {
            game.Betting(0.001 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            User memory delegatedUser = game.delegationRole(user4);
            assertEq(uint(delegatedUser.class), uint(WarClass.Warrior));            
        }
        vm.stopPrank();

        loggingPlayersStat(game);
    }

    function testPlayGame_Warrior() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.defender).HP, 290);
    }

    function testPlayGame_Archer() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Archer);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.piercingArrow(); // 25:50
            game.multiShot(); // 35:65
            game.explosiveShot(); // 30:60
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 225);
        vm.startPrank(user1);
        {
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.defender).HP, 290);
    }

    function testPlayGame_mage() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Mage);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.fireBall(); // 30:70
            game.heal(); // 25:50
            game.lightningBolt(); // 30:60
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 270);
        vm.startPrank(user1);
        {
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.defender).HP, 340);
    }

    function testPlayGame_Druid() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Druid);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.naturesWrath(); // 25:45
            game.healingTouch(); // 25:50
            game.thornArmor(); // 15:25
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 330);
        vm.startPrank(user1);
        {
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.defender).HP, 325);
    }

    function testPlayGameDeclareVictory() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            game.berserkSlash(); // 20:40
            game.shieldBash(); // 15:20
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.destructStab(); // 30:50
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
        }
        vm.stopPrank();
    }

    function testPlayGameDeclareVictoryAndWinNFT() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            uint256 balanceBefore = MAT.balanceOf(user1);
            game.berserkSlash(); // 20:40
            game.shieldBash(); // 15:20
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.destructStab(); // 30:50
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            game.berserkSlash(); // 20:40
            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
            
            uint256 NFTId = game.winNFTAndTakeWarToken();
            assertEq(MAN.ownerOf(NFTId), user1);
            assertEq(MAT.balanceOf(user1), 0.02 ether * 90 / 100 + balanceBefore);
        }
        vm.stopPrank();
    }

    function testInvalidUserCallSkillNotPass() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            loggingPlayersStat(game);
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            vm.expectRevert("YOU_ARE_NOT_ARCHER");
            game.multiShot(); // archer skill 
        }
        vm.stopPrank();
    }

    function testPhaseInvalidCall() public {
        GameInstance game;
        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            assertEq(user2.balance, 1); // 1 ether와 함께 msg.data를 받음
            game = GameInstance(abi.decode(data, (address)));

            game.Betting(0.001 ether, 50, 50);
            game.setGame();
        }
        vm.stopPrank();

        vm.startPrank(user2);
        {
            game.Betting(0.001 ether, 60, 40);
            vm.expectRevert("NOT_CLASS_SELECTION_PHASE");
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
    }

    function testAttackWithMulticallWarrior() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Warrior);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            bytes[] memory data = new bytes[](10);
            data[0] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[1] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[2] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[3] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[4] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[5] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[6] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[7] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[8] = (abi.encodeWithSelector(game.berserkSlash.selector));
            data[9] = (abi.encodeWithSelector(game.berserkSlash.selector));
            game.multicall(data);

            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
            loggingPlayersStat(game);
        }
        vm.stopPrank();
        // test multicall to execute berserkSlash 10 times
    }

    function testAttackWithMulticallArcher() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Archer);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            bytes[] memory data = new bytes[](8);
            data[0] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[1] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[2] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[3] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[4] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[5] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[6] = (abi.encodeWithSelector(game.piercingArrow.selector));
            data[7] = (abi.encodeWithSelector(game.piercingArrow.selector));
            game.multicall(data);

            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
            loggingPlayersStat(game);
        }
        vm.stopPrank();
        // test multicall to execute berserkSlash 10 times
    }

    function testAttackWithMulticallMage() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Mage);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            bytes[] memory data = new bytes[](6);
            data[0] = (abi.encodeWithSelector(game.lightningBolt.selector));
            data[1] = (abi.encodeWithSelector(game.fireBall.selector));
            data[2] = (abi.encodeWithSelector(game.fireBall.selector));
            data[3] = (abi.encodeWithSelector(game.lightningBolt.selector));
            data[4] = (abi.encodeWithSelector(game.fireBall.selector));
            data[5] = (abi.encodeWithSelector(game.fireBall.selector));
            game.multicall(data);

            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
            loggingPlayersStat(game);
        }
        vm.stopPrank();
        // test multicall to execute berserkSlash 10 times
    }

    function testAttackWithMulticallDruid() public {
        GameInstance game;

        vm.startPrank(user1);
        {
            (suc, data) = address(proxy).call(abi.encodeWithSelector(v1.invite.selector, user2, "let's fight"));
            assertEq(suc, true);
            game = GameInstance(abi.decode(data, (address)));
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.Betting(0.01 ether, 60, 40);
            game.setGame();
            assertEq(uint256(game.gamePhase()), uint256(GamePhase.classPhase));
        }
        vm.stopPrank();
        vm.startPrank(user1);
        {
            game.selectClass(WarClass.Druid);
        }
        vm.stopPrank();
        vm.startPrank(user2);
        {
            game.selectClass(WarClass.Warrior);
            assertEq(uint(game.gamePhase()), uint(GamePhase.warPhase));
            game.berserkSlash(); // 20:40
            game.destructStab(); // 30:50
            game.shieldBash(); // 15:20
        }
        vm.stopPrank();
        assertEq(game.getPlayerStat(Role.challenger).HP, 290);
        vm.startPrank(user1);
        {
            bytes[] memory data = new bytes[](16);
            data[0] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[1] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[2] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[3] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[4] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[5] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[6] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[7] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[8] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[9] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[10] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[11] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[12] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[13] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[14] = (abi.encodeWithSelector(game.thornArmor.selector));
            data[15] = (abi.encodeWithSelector(game.thornArmor.selector));
            game.multicall(data);

            loggingPlayersStat(game);
            assertEq(game.getPlayerStat(Role.defender).HP, 0);
            assertEq(game.declareVictory(), user1);
            assertEq(uint(game.gamePhase()), uint(GamePhase.winPhase));
        }
        vm.stopPrank();
        // test multicall to execute berserkSlash 10 times
    }

    receive() external payable {}
}
