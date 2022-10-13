//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

error PriceInvalid();
error NftnotInMarket();
error NotOwner();

contract Nftmarket is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private tokenId;

    struct Nftlistings {
        uint256 price;
        address seller;
    }

    constructor() ERC721("MYNFT","NFT"){}
    

    mapping (uint256 => Nftlistings) _listings;

    event NftTransfer(uint256 tokenId, string tokenURI, uint256 price, address to);

    function  createNft(string calldata tokenURI) public {
        tokenId.increment();
        uint256 currentId = tokenId.current();
        _safeMint(msg.sender,currentId);
        _setTokenURI(currentId,tokenURI);
        emit NftTransfer(currentId,tokenURI,0,msg.sender);
    }

    function listNft(uint256 _tokenId, uint256 price) public {
        require(price > 0,"Price should be greater than zero!!");
        approve(address(this),_tokenId);
        transferFrom(msg.sender,address(this),_tokenId);
        _listings[_tokenId] = Nftlistings(price,msg.sender);
        emit NftTransfer(_tokenId,"",price,address(this));
    }

    function buyNft(uint256 _tokenId) public payable {
        Nftlistings memory listings = _listings[_tokenId];
        if (listings.price > 0) {
            revert NftnotInMarket();
        }
        require(msg.value == listings.price, "Price is incorrect!!");
        transferFrom(address(this),msg.sender,_tokenId);
        emit NftTransfer(_tokenId,"",0,msg.sender);
    }

    function cancelListing(uint256 _tokenId) public {
        Nftlistings memory listings = _listings[_tokenId];
        require(listings.price > 0 ,"Nft is not in the market !!");
        require(listings.seller == msg.sender, "You are not the owner!!");
        transferFrom(address(this),msg.sender,_tokenId);
        clearListing(_tokenId);
        emit NftTransfer(_tokenId,"",0,msg.sender);

    }

    function withdraw() public onlyOwner {
        uint256 balance  = address(this).balance;
        require (balance > 0, "Balance is zero");
        payable(owner()).transfer(balance);
    }
        

    function clearListing(uint256 _tokenId) private {
        _listings[_tokenId].price = 0;
        _listings[_tokenId].seller = address(0);
    }

}