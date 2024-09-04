// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MultiAttackToken is ERC20 {
    address owner;
    mapping(address => bool) private instanceAddresses;
    mapping(address => bool) private implementationAddresses;

    constructor() ERC20("Multi Attack Token", "MAT") {
        owner = msg.sender;
    }

    modifier onlyGame() {
        require(implementationAddresses[msg.sender]);
        _;
    }

    /**
     * registerInstance, deleteInstance를 호출하는 Game컨트랙트를 등록하는 함수,
     */
    function registerImplementation(address implementationAddr) public {
        require(!implementationAddresses[implementationAddr], "ALREADY_REGISTERED");
        require(msg.sender == owner || implementationAddresses[msg.sender], "UNAUTHORIZED_SENDER");
        implementationAddresses[implementationAddr] = true;
    }

    /**
     * transferFrom 을 호출하는 instance목록에 등록하기 위한 함수
     */
    function registerInstance(address instanceAddr) public onlyGame {
        require(!instanceAddresses[instanceAddr], "ALREADY_REGISTERED");

        instanceAddresses[instanceAddr] = true;
    }

    /**
     * 등록 목록을 삭제하기 위한 함수
     */
    function deleteInstance(address instanceAddr) public {
        require(instanceAddresses[msg.sender], "UNAUTHORIZED_SENDER");

        instanceAddresses[instanceAddr] = false;
    }

    /**
     * 게임에서 instance에 transfer를 하는 상황이라면, user가 allow를 했을 것이기 때문에, approve없이도 할 수 있게 함
     */
    function transferFrom(address from, address to, uint256 value) public override returns (bool) {
        if (instanceAddresses[msg.sender] || implementationAddresses[msg.sender]) {
            _transfer(from, to, value);
            return true;
        } else {
            return super.transferFrom(from, to, value); // 이렇게 쓰는게 맞나?
        }
    }

    /**
     * ETH와 1:1로 매칭되는 가치를 지닌 MultiAttackToken을 발행해주는 함수
     * 유의미한 전투가 될 수 있도록 하기 위하여 최소 mint수량은 0.001 ether이다.
     */
    function mint() public payable {
        require(msg.value >= 0.001 ether, "INSUFFICIENT_AMOUNT_DEPOSITED");
        
        _mint(msg.sender, msg.value);
    }

    /**
     * MultiAttackToken을 burn하고, 그 수량만큼의 이더를 반환해주는 함수.
     */
    function burn(uint256 value) public {
        require(value >= 0.001 ether, "TOKEN_AMOUNT_TOO_SMALL");
        _burn(msg.sender, value);
        (bool suc,) = msg.sender.call{value: value}("");
        require(suc, "TOKEN_ETH_EXCHANGE_FAILED");
    }
}
