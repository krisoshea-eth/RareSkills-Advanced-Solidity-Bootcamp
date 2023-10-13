// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;

import "@openzeppelin/contracts@4.3.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.3.2/access/Ownable2Step.sol";
import "./QueryNft.sol";

contract NftEnumerable is ERC721Enumerable, Ownable2Step {
    QueryNft public queryNft;

    // Events
    event TokenMinted(address to, uint256 tokenId);

    constructor(QueryNft _QueryNft, address _initialOwner) ERC721("NFTenumerable", "NET") Ownable(_initialOwner) {
        queryNft = _QueryNft;

        for (uint256 i = 1; i <= 20; i++) {
            _safeMint(_initialOwner, i);
            queryNft.updatePrimeMapping(i);
        }
    }

    function safeMint(address to, uint256 tokenId) external onlyOwner {
        require(to != address(0), "Invalid address");
        _safeMint(to, tokenId);
        queryNft.updatePrimeMapping(tokenId);
        emit TokenMinted(to, tokenId); // Emit event
    }
}
