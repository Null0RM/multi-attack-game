// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";
import {GameInstance} from "./GameInstance.sol";

contract MultiAttack is UUPSUpgradeable, OwnableUpgradeable, PausableUpgradeable {
    // ERC20 & ERC721 tokenomics information
    MultiAttackToken MAT;
    MultiAttackNFT MAN;

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

    function invite(address _to, string calldata message) public payable returns (address newInstance) {
        require(MAT.balanceOf(msg.sender) >= 0.0001 ether, "INSUFFICIENT_INVITE_FEE");
        MAT.transferFrom(msg.sender, address(this), 0.0001 ether); // 참가비로 지출

        (bool suc,) = _to.call{value: 1}(abi.encodePacked(message)); // msg를 통해 게임으로 초대
        require(suc, "INVITE_FAILED_BY_SEND_FAILED");

        GameInstance instance = new GameInstance(msg.sender, _to, MAT, MAN);
        
        newInstance = address(instance);
        emit createInstance(newInstance);
    }

    // with libs
    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}
}
