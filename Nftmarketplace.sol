//SPDX-License-Identifier:MIT

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

error PriceIncorrect();

pragma solidity ^0.8.16;

contract Nftmarketplace is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private tokenIds;
    Counters.Counter private itemsSold;
    
    address payable immutable owner;
    uint256 constant listingPrice = 0.0009 ether;

    

    struct NftItems {
        uint256 tokenId;
        uint256 price;
        address payable seller;
        address payable owner;
        bool sold;
    }
    event NftmarketItemCreated( 
        uint256 indexed tokenId,
        address seller, 
        address buyer,  
        uint256 price, 
        bool sold);

    constructor () ERC721("NFT Marketplace","MyNft") {
        owner = payable(msg.sender);
    }

    mapping (uint256 => NftItems) nftItemsId;

    function createNftToken(string memory tokenURI, uint256 price) public payable returns(uint256){
        tokenIds.increment();
        uint256 tokenId = tokenIds.current();
        _mint(msg.sender,tokenId);
        _setTokenURI(tokenId,tokenURI);
        createNftItem(tokenId,price);
        return tokenId;
    }

    function createNftItem(uint256 tokenId,uint256 price) private {
        if (price <= 0) {
            revert PriceIncorrect();
        }
        if (msg.value != listingPrice) {
            revert PriceIncorrect();
        }
        nftItemsId[tokenId] = NftItems (
            tokenId,
            price,
            payable(msg.sender),
            payable(address(this)),
            false
        );
        _transfer(msg.sender,address(this),tokenId);
        emit NftmarketItemCreated(tokenId,msg.sender,address(this),price,false);
    }

    function buyNftItem(uint256 tokenId) public payable{
        address seller = nftItemsId[tokenId].seller;
        if (msg.value != nftItemsId[tokenId].price) {
            revert PriceIncorrect();
        }
        nftItemsId[tokenId].owner = payable(msg.sender);
        nftItemsId[tokenId].seller = payable(address(0));
        nftItemsId[tokenId].sold = true;
        itemsSold.increment();
        _transfer(msg.sender,address(this),tokenId);
        (bool success,) = payable(owner).call{value : listingPrice}("");
        require(success);
        (bool success1,) = payable(seller).call{value : msg.value}("");
        require(success1);
    }

    function fetchNfts() public view returns(NftItems[] memory){
        uint256 itemCount = tokenIds.current();
        uint256 unSoldNftCount = itemCount - itemsSold.current();
        uint256 currentIndex = 0;

        NftItems[] memory items = new NftItems[](unSoldNftCount);
        for (uint256 i = 0; i < itemCount; i++){
            if (nftItemsId[i+1].owner == address(this)){
                uint256 currentId = i + 1;
                NftItems storage currentItem = nftItemsId[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }

    function fetchMyNfts() public view returns(NftItems[] memory) {
        uint256 itemCount = tokenIds.current();
        uint256 unSoldNftCount = itemCount - itemsSold.current();
        uint256 currentIndex = 0;

        NftItems[] memory items = new NftItems[](unSoldNftCount);
        for (uint256 i = 0; i < itemCount; i++ ){
            if(nftItemsId[i+1].owner == msg.sender){
                uint256 currentId = i + 1;
                NftItems storage currentItem = nftItemsId[currentId];
                items[currentIndex] = currentItem;
                currentIndex++;
            }
        }
        return items;
    }
}
