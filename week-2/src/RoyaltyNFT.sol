// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import "@openzeppelin/contracts@4.3.2/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts@4.3.2/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts@4.3.2/access/Ownable2Step.sol";
import "@openzeppelin/contracts@4.3.2/utils/Counters.sol";
import "@openzeppelin/contracts@4.3.2/utils/structs/BitMaps.sol";
import "@openzeppelin/contracts@4.3.2/utils/cryptography/MerkleProof.sol";

contract RoyaltyNFT is ERC721, ERC721Royalty, ERC721Enumerable, ERC721URIStorage, Ownable2Step {
    using Strings for uint256;
    using Counters for Counters.Counter;
    using BitMaps for BitMaps.BitMap;

    bytes32 public immutable merkleRoot;
    BitMaps.BitMap private _discountList;

    Counters.Counter private _tokenIds;
    string public metadataURI;

    address public artist;
    uint96 public royaltyFee;
    uint256 public constant maxSupply = 20;

    mapping(uint256 => bool) public isListed;
    mapping(uint256 => uint256) public price;
    mapping(uint256 => address) public lister;

    event NFTMinted(address indexed mintedBy, uint256 indexed tokenId);
    event FundsWithdrawn(address indexed owner, uint256 amount);

    constructor(bytes32 _merkleRoot, address _initialOwner, string memory _metadataURI, address _artist)
        ERC721("Royalty", "RYLT")
        Ownable(_initialOwner)
    {
        merkleRoot = _merkleRoot;
        metadataURI = _metadataURI;
        artist = _artist;
        royaltyFee = 250;
        _setDefaultRoyalty(_artist, 250);
    }

    function mint(uint256 _tokenId, uint256 cost) public payable {
        require(totalSupply() < maxSupply, "Max supply reached");
        require(cost == 2 ether, "Incorrect cost amount entered");

        uint256 tokenId = _tokenIds.current();

        (address artist, uint256 royaltyFee) = royaltyInfo(_tokenId, cost);

        // Pay the artist
        (bool sent,) = artist.call{value: royaltyFee}("");
        require(sent);

        // Pay the lister
        (sent,) = lister[_tokenId].call{value: cost - royaltyFee}("");
        require(sent);

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(metadataURI, tokenId.toString(), ".json")));

        _tokenIds.increment();

        emit NFTMinted(msg.sender, tokenId);
    }

    function discountMint(bytes32[] calldata proof, uint256 index, uint256 _tokenId, uint256 cost) public payable {
        uint256 amount = 1;

        //Checks if caller has already minted discounted NFT
        require(!BitMaps.get(_discountList, index), "Already Minted Discounted NFT");
        //Verify proof
        _verifyProof(proof, index, amount, msg.sender);

        require(totalSupply() < maxSupply);
        require(cost == 1 ether);

        //Set discounted Nft mint as claimed
        BitMaps.setTo(_discountList, index, true);

        uint256 tokenId = _tokenIds.current();

        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, string(abi.encodePacked(metadataURI, tokenId.toString(), ".json")));

        _tokenIds.increment();
    }

    function _verifyProof(bytes32[] memory proof, uint256 index, uint256 amount, address addr) private view {
        bytes32 leaf = keccak256(bytes.concat(keccak256(abi.encode(addr, index, amount))));
        require(MerkleProof.verify(proof, merkleRoot, leaf), "Invalid proof");
    }

    function listNftForSale(uint256 _tokenId, uint256 _price) public {
        require(!isListed[_tokenId]);

        safeTransferFrom(msg.sender, address(this), _tokenId);

        lister[_tokenId] = msg.sender;
        isListed[_tokenId] = true;
        price[_tokenId] = _price;
    }

    function secondaryBuy(uint256 _tokenId) public payable {
        require(isListed[_tokenId]);
        require(msg.value >= price[_tokenId]);

        isListed[_tokenId] = false;

        (address artist, uint256 royaltyFee) = royaltyInfo(_tokenId, price[_tokenId]);

        // Pay the artist
        (bool sent,) = artist.call{value: royaltyFee}("");
        require(sent);

        // Pay the Nft lister
        (sent,) = lister[_tokenId].call{value: msg.value - royaltyFee}("");
        require(sent);

        safeTransferFrom(address(this), msg.sender, _tokenId);
    }

    function withdrawFunds(uint256 amount) public onlyOwner {
        require(amount <= address(this).balance, "Insufficient funds");
        payable(owner()).transfer(amount);

        emit FundsWithdrawn(msg.sender, amount);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId, uint256 batchSize)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721URIStorage, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
