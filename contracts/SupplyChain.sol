// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;

contract SupplyChain {

  address contractOwner;

  uint  sku;

  mapping(uint => Item) items; // (upc => Item)

  enum State
    {
        ForSale, // 0
        Sold, // 1
        Shipped, // 2
        Received // 3
    }

  struct Item {
	string name; // Name
	uint skuCount;  // SKU
 	uint price; // Price
	State state;  // State
	address seller;  // Seller
	address buyer;  // Buyer
    }
  
    event ForSale(uint skuCount);
    event Sold(uint skuCount);
    event Shipped(uint skuCount);
    event Received(uint skuCount);


  /* 
   * Modifiers
   */

  modifier isOwner() {
        require(msg.sender == contractOwner, "Only the owner can perform this operation");
        _;
    }

   modifier verifyCaller (address _address) {
        require(msg.sender == _address);
        _;
    }

   modifier paidEnough(uint _price) {
        require(msg.value >= _price, "Not enough was paid for the item");
        _;
    }

  modifier checkValue(uint _skuCount) {
        _;
        uint _price = items[_skuCount].price;
        uint amountToReturn = msg.value - _price;

        address payable consumerAddressPayable = _make_payable(items[_skuCount].consumerID);
        consumerAddressPayable.transfer(amountToReturn);
    }


 modifier forSale(uint _skuCount) {
        require(items[_skuCount].itemState == State.ForSale, "The item is not yet for sale");
        _;
    }
  
modifier sold(uint _skuCount) {
        require(items[_skuCount].itemState == State.Sold, "The item is not yet sold");
        _;
    }

  modifier shipped(uint _skuCount) {
        require(items[_sku].itemState == State.Shipped, "The item is not yet shipped");
        _;
    }

 modifier received(uint _skuCount) {
        require(items[_skuCount].itemState == State.Received, "The item is not yet received");
        _;
    }

 constructor() public payable {
        contractOwner = msg.sender;
        sku = 1;
    }
    
    

  function ForSaleItem(
        uint _skuCount,
        address _buyer,
          string memory _name,
        string memory _productNotes) public isOwner
    {
        items[_skuCount] = Item({
		sku: _skuCount;
		name: _name;
		price: uint(0),
		state: State.ForSale;
		seller: msg.sender;
		buyer: address(0) 
            });

        sku = sku + 1;
 emit LogForSale(sku);
    return true;
  }



function sellItem(uint _skuCount, uint _price) public isOwner (_skuCount)
    {
        items[_skuCount].itemState = State.ForSale;
        items[_skuCount].Price = _price;
        emit ForSale(_skuCount);
    }

    function buyItem(uint _skuCount) public payable isOwner forSale(_skuCount) paidEnough(items[_sku].Price)
    {
        items[_skuCount].ownerID = contractOwner;
        items[_skuCount].distributorID = msg.sender;
        items[_skuCount].State = State.Sold;

        address payable consumerAddressPayable = _make_payable(items[_skuCount].sondumerID);
        consumerAddressPayable.transfer(msg.value);
        

        emit Sold(_skuCount);
    }

    function soldItem(uint _skuCount) public isOwner sold(_skuCount)
    {
        items[_skuCount].itemState = State.Shipped;
        emit Shipped(_skuCount);
    }
    
     function shipItem(uint _skuCount) public isOwner shipped(_skuCount)
    {
        items[_skuCount].itemState = State.Shipped;
        emit Shipped(_skuCount);
    }

}
