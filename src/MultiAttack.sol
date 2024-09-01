// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";
import {GameInstance} from "./Instance.sol";

contract MultiAttack is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable, IMultiAttack {
    // ERC20 & ERC721 tokenomics information
    MultiAttackToken MAT;
    MultiAttackNFT MAN;
    
    // enumerations
    Class public class;
    GamePhase public gamePhase;

    event createInstance(address newInstance);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _MAT, address _MAN) public initializer {
        __Pausable_init();
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();

        MAT = MultiAttackToken(_MAT);
        MAN = MultiAttackNFT(_MAN);      
        
    }

    function invite(address _to, string msg) public payable returns (address newInstance) {
        require(MAT.balanceOf(msg.sender) >= 0.0001 ether, "INSUFFICIENT_INVITE_FEE");
        MAT.transferFrom(msg.sender, address(this), 0.0001 ether); // 참가비로 지출
        
        (bool suc, ) = _to.call{value: 0.001, data: abi.encode(msg)}(""); // msg를 통해 게임으로 초대
        require(suc, "INVITE_FAILED_BY_SEND_FAILED");
        
        newInstance = new GameInstance();
        
        emit createInstance(newInstance);
    }

    // with libs
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
