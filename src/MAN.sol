// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract MultiAttackNFT is ERC721 {
    address owner;
    mapping(address => bool) private instanceAddresses;
    mapping(address => bool) private proxyAddresses;

    uint256 tokenId;

    constructor() ERC721("Multi Attack NFT", "MAN") {
        owner = msg.sender;
    }

    modifier onlygame() {
        require(proxyAddresses[msg.sender]);
        _;
    }

    modifier onlyInstance() {
        require(instanceAddresses[msg.sender]);
        _;
    }

    function registerProxy(address proxyAddr) public {
        require(!proxyAddresses[proxyAddr], "ALREADY_REGISTERED");
        require(msg.sender == owner || proxyAddresses[msg.sender], "UNAUTHORIZED_SENDER");

        proxyAddresses[proxyAddr] = true;
    }

    function deleteInstance(address instanceAddr) public onlygame {
        require(instanceAddresses[instanceAddr], "NON_EXISTING_ADDRESS");

        instanceAddresses[instanceAddr] = false;
    }

    function registerInstance(address instanceAddr) public onlygame {
        require(!instanceAddresses[instanceAddr], "ALREADY_REGISTERED");

        instanceAddresses[instanceAddr] = true;
    }

    function mint(address _to) public onlyInstance returns (uint256 id) {
        // 여길 어떻게 더 채워야할까?
        id = tokenId;
        _mint(_to, tokenId);
        tokenId++;
    }
}
