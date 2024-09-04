// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MultiAttackToken} from "./MAT.sol";
import {MultiAttackNFT} from "./MAN.sol";

contract MultiAttackProxy is ERC1967Proxy {
    bool onlyOnce;

    constructor(address _implementation, address MAT, address MAN)
        ERC1967Proxy(_implementation, abi.encodeWithSelector(0x485cc955, MAT, MAN))
    {}
    // initialize

    /** 
    단 한번만 호출할 수 있는 함수
     */
    function registerImplementation(address MAT, address MAN, address newImplementation) external {
        require(onlyOnce == false, "only once");
        onlyOnce = true;
        MultiAttackNFT(MAN).registerImplementation(newImplementation);
        MultiAttackToken(MAT).registerImplementation(newImplementation);
    }
}
