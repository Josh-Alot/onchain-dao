// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CryptoDevsNFT is ERC721Enumerable {
    constructor() ERC721("CryptoDevs", "CD") {} // initializes the ERC721 contract

    function mint() public { // public mint function to get an NFT
        _safeMint(msg.sender, totalSupply());
    }
}