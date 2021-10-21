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
	uint sku;  // SKU
 	uint price; // Price
	State state;  // State
	address seller;  // Seller
	address buyer;  // Buyer
    }
  
    event ForSale(uint sku);
    event Sold(uint sku);
    event Shipped(uint sku);
    event Received(uint sku);


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

  modifier checkValue(uint _sku) {
        _;
        uint _price = items[_sku].price;
        uint amountToReturn = msg.value - _price;

        address payable consumerAddressPayable = _make_payable(items[_sku].consumerID);
        consumerAddressPayable.transfer(amountToReturn);
    }


 modifier forSale(uint _sku) {
        require(items[_sku].itemState == State.ForSale, "The item is not yet for sale");
        _;
    }
  
modifier sold(uint _sku) {
        require(items[_sku].itemState == State.Sold, "The item is not yet sold");
        _;
    }

  modifier shipped(uint _sku) {
        require(items[_sku].itemState == State.Shipped, "The item is not yet shipped");
        _;
    }

 modifier received(uint _sku) {
        require(items[_sku].itemState == State.Received, "The item is not yet received");
        _;
    }

 constructor() public payable {
        contractOwner = msg.sender;
        sku = 1;
    }
    
    

  function ForSaleItem(
        uint _sku,
        address _buyer,
          string memory _name,
        string memory _productNotes) public isOwner
    {
        items[_sku] = Item({
		sku: _sku;
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



function sellItem(uint _sku, uint _price) public isOwner (_sku)
    {
        items[_sku].itemState = State.ForSale;
        items[_sku].Price = _price;
        emit ForSale(_sku);
    }

    function buyItem(uint _sku) public payable isOwner forSale(_sku) paidEnough(items[_sku].Price)
    {
        items[_sku].ownerID = contractOwner;
        items[_sku].distributorID = msg.sender;
        items[_sku].State = State.Sold;

        address payable consumerAddressPayable = _make_payable(items[_sku].sondumerID);
        consumerAddressPayable.transfer(msg.value);
        

        emit Sold(_sku);
    }

    function soldItem(uint _sku) public isOwner sold(_sku)
    {
        items[_sku].itemState = State.Shipped;
        emit Shipped(_sku);
    }
    
     function shipItem(uint _sku) public isOwner shipped(_sku)
    {
        items[_sku].itemState = State.Shipped;
        emit Shipped(_sku);
    }

}
