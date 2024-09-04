// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MultiAttackNFT is ERC721 {
    address owner;
    mapping(address => bool) private instanceAddresses;
    mapping(address => bool) private implementationAddresses;

    uint256 tokenId;

    constructor() ERC721("Multi Attack NFT", "MAN") {
        owner = msg.sender;
    }

    modifier onlygame() {
        require(implementationAddresses[msg.sender]);
        _;
    }

    modifier onlyInstance() {
        require(instanceAddresses[msg.sender]);
        _;
    }

    function registerImplementation(address implementationAddr) public {
        require(!implementationAddresses[implementationAddr], "ALREADY_REGISTERED");
        require(msg.sender == owner || implementationAddresses[msg.sender], "UNAUTHORIZED_SENDER");

        implementationAddresses[implementationAddr] = true;
    }

    function registerInstance(address instanceAddr) public onlygame {
        require(!instanceAddresses[instanceAddr], "ALREADY_REGISTERED");

        instanceAddresses[instanceAddr] = true;
    }

    function mint(address _to) public onlyInstance returns (uint256 id) {
        // 여길 어떻게 더 채워야할까?
        instanceAddresses[msg.sender] = false;
        id = tokenId;
        _mint(_to, tokenId);
        tokenId++;
    }
}
