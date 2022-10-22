//SPDX-License-Identifier:MIT
pragma solidity ^0.8.16;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

error PriceIncorrectError();
error NotAuthorised();

contract Ecommerce {
    struct Products {
        string Name;
        string Description;
        uint256 Prod_id;
        address buyer;
        address seller;
        uint256 price ;
        bool isdelivered;
    }

    AggregatorV3Interface internal eth_in_usd;
    Products[] product;

    function ethInUsd() public view returns(uint) {
          (,uint price,,,) = eth_in_usd.latestRoundData();
        return (price * 1e18);
   }
    
    function usdValue(uint _amount) public view returns(uint) {
        uint Valueprice = ethInUsd();
        uint AmountIndollors = (Valueprice * _amount) / 1e18;
        return AmountIndollors;
    }
   
    function registerProduct(string memory _name, string memory _desc, uint256 _price) private {
        Products memory prod;
        if (_price < 0){
            revert PriceIncorrectError();
        }
        if (prod.seller == msg.sender) {
            revert NotAuthorised();
        }
        prod.Name = _name;
        prod.Description = _desc;
        prod.price = usdValue(_price);
        prod.seller = msg.sender;
        uint256 counter;
        counter ++;
        prod.Prod_id = counter;
        product.push(prod);

    }

    function buyProd(uint256 _prodId) payable public {
        uint256 priceInUsd = usdValue(msg.value);
        if (priceInUsd != product[_prodId-1].price) {
            revert PriceIncorrectError();
        }

        if ( msg.sender == product[_prodId-1].seller){
            revert NotAuthorised();
        }

        product[_prodId - 1].buyer = msg.sender;


    }

    function delivered(uint256 _prodId) public {
        if (msg.sender != product[_prodId - 1].buyer) {
            revert NotAuthorised();
        }
        (bool success,) = product[_prodId-1].seller.call{value : address(this).balance}("");
        require(success);
    }
}
