//SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

//tokenURI on an NFT is a unique identifier of what the token "looks" like
//A URI could be an API call over HTTPS, an IPFS hash, or anything else unique.
//These show what an NFT looks like, and its attributes.

contract NFT is ERC721URIStorage {
    uint256 public tokenCount = 0;

    constructor() ERC721("Awisum NFT", "ANX") {}

    function mint(string memory _tokenURI) external returns (uint256) {
        tokenCount++; //serves as an ID
        _safeMint(msg.sender, tokenCount);
        _setTokenURI(tokenCount, _tokenURI);
        return (tokenCount);
    }
}
