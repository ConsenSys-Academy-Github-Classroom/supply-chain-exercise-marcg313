// SPDX-License-Identifier: MIT
pragma solidity >=0.5.16 <0.9.0;


import "https://github.com/ConsenSys-Academy-Github-Classroom/supply-chain-exercise-marcg313/tree/master/test/ConsumerRole.sol";
import "https://github.com/ConsenSys-Academy-Github-Classroom/supply-chain-exercise-marcg313/tree/master/test/DistributorRole.sol";
import "https://github.com/ConsenSys-Academy-Github-Classroom/supply-chain-exercise-marcg313/tree/master/test/FarmerRole.sol";
import "https://github.com/ConsenSys-Academy-Github-Classroom/supply-chain-exercise-marcg313/tree/master/test/RetailerRole.sol";

contract SupplyChain is ConsumerRole, DistributorRole, FarmerRole, RetailerRole {

    address contractOwner;
    uint  upc;
    uint  sku;

    mapping(uint => Item) items; // (upc => Item)

    // Define a public mapping 'itemsHistory' that maps the UPC to an array of TxHash,
    // that track its journey through the supply chain -- to be sent from DApp.
    mapping(uint => string[]) itemsHistory; // (upc => [progress?])

    enum State
    {
        Harvested, // 0
        Processed, // 1
        Packed, // 2
        ForSale, // 3
        Sold, // 4
        Shipped, // 5
        Received, // 6
        Purchased   // 7
    }

    State constant defaultState = State.Harvested;

    struct Item {
        uint sku;  // Stock Keeping Unit (SKU)
        uint upc; // Universal Product Code (UPC), generated by the Farmer, goes on the package, can be verified by the Consumer
        address ownerID;  // Metamask-Ethereum address of the current owner as the product moves through 8 stages
        address originFarmerID; // Metamask-Ethereum address of the Farmer
        string originFarmName; // Farmer Name
        string originFarmInformation;  // Farmer Information
        string originFarmLatitude; // Farm Latitude
        string originFarmLongitude;  // Farm Longitude
        uint productID;  // Product ID potentially a combination of upc + sku
        string productNotes; // Product Notes
        uint productPrice; // Product Price
        State itemState;  // Product State as represented in the enum above
        address distributorID;  // Metamask-Ethereum address of the Distributor
        address retailerID; // Metamask-Ethereum address of the Retailer
        address consumerID; // Metamask-Ethereum address of the Consumer
    }

    event Harvested(uint upc);
    event Processed(uint upc);
    event Packed(uint upc);
    event ForSale(uint upc);
    event Sold(uint upc);
    event Shipped(uint upc);
    event Received(uint upc);
    event Purchased(uint upc);


    /* Modifiers ************************ */

    modifier onlyOwner() {
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

    modifier checkValue(uint _upc) {
        _;
        uint _price = items[_upc].productPrice;
        uint amountToReturn = msg.value - _price;

        address payable consumerAddressPayable = _make_payable(items[_upc].consumerID);
        consumerAddressPayable.transfer(amountToReturn);
    }

    modifier harvested(uint _upc) {
        require(items[_upc].itemState == State.Harvested, "The item is not yet harvested");
        _;
    }

    modifier processed(uint _upc) {
        require(items[_upc].itemState == State.Processed, "The item is not yet processed");
        _;
    }

    modifier packed(uint _upc) {
        require(items[_upc].itemState == State.Packed, "The item is not yet packed");
        _;
    }

    modifier forSale(uint _upc) {
        require(items[_upc].itemState == State.ForSale, "The item is not yet for sale");
        _;
    }

    modifier sold(uint _upc) {
        require(items[_upc].itemState == State.Sold, "The item is not yet sold");
        _;
    }

    modifier shipped(uint _upc) {
        require(items[_upc].itemState == State.Shipped, "The item is not yet shipped");
        _;
    }

    modifier received(uint _upc) {
        require(items[_upc].itemState == State.Received, "The item is not yet received");
        _;
    }

    modifier purchased(uint _upc) {
        require(items[_upc].itemState == State.Purchased, "The item is not yet purchased");
        _;
    }


    /* Constructor & utils ************************ */

    constructor() public payable {
        contractOwner = msg.sender;
        sku = 1;
        upc = 1;
    }

    function kill() public {
        if (msg.sender == contractOwner) {
            address payable ownerAddressPayable = _make_payable(contractOwner);
            selfdestruct(ownerAddressPayable);
        }
    }

    function _make_payable(address x) internal pure returns (address payable) {
        return address(uint160(x));
    }

    /* Functions ************************ */

    function harvestItem(
        uint _upc,
        address _originFarmerID,
        string memory _originFarmName,
        string memory _originFarmInformation,
        string memory _originFarmLatitude,
        string memory _originFarmLongitude,
        string memory _productNotes) public onlyFarmer
    {
        items[_upc] = Item({
            sku: sku,
            upc: _upc,
            ownerID: contractOwner,
            originFarmerID: _originFarmerID,
            originFarmName: _originFarmName,
            originFarmInformation: _originFarmInformation,
            originFarmLatitude: _originFarmLatitude,
            originFarmLongitude: _originFarmLongitude,
            productID: _upc + sku,
            productNotes: _productNotes,
            productPrice: uint(0),
            itemState: defaultState,
            distributorID: address(0),
            retailerID: address(0),
            consumerID: address(0)
            });

        sku = sku + 1;

        emit Harvested(_upc);
    }

    function processItem(uint _upc) public onlyFarmer harvested(_upc)
    {
        items[_upc].itemState = State.Processed;
        emit Processed(_upc);
    }

    function packItem(uint _upc) public onlyFarmer processed(_upc)
    {
        items[_upc].itemState = State.Packed;
        emit Packed(_upc);
    }

    function sellItem(uint _upc, uint _price) public onlyFarmer packed(_upc)
    {
        items[_upc].itemState = State.ForSale;
        items[_upc].productPrice = _price;
        emit ForSale(_upc);
    }

    function buyItem(uint _upc) public payable onlyDistributor forSale(_upc) paidEnough(items[_upc].productPrice)
    {
        items[_upc].ownerID = contractOwner;
        items[_upc].distributorID = msg.sender;
        items[_upc].itemState = State.Sold;

        address payable originFarmerAddressPayable = _make_payable(items[_upc].originFarmerID);
        originFarmerAddressPayable.transfer(msg.value);

        emit Sold(_upc);
    }

    function shipItem(uint _upc) public onlyDistributor sold(_upc)
    {
        items[_upc].itemState = State.Shipped;
        emit Shipped(_upc);
    }

    function receiveItem(uint _upc) public onlyRetailer shipped(_upc)
    {
        items[_upc].ownerID = contractOwner;
        items[_upc].retailerID = msg.sender;
        items[_upc].itemState = State.Received;
        emit Received(_upc);
    }

    function purchaseItem(uint _upc) public onlyConsumer received(_upc)
    {
        items[_upc].ownerID = contractOwner;
        items[_upc].consumerID = msg.sender;
        items[_upc].itemState = State.Purchased;
        emit Purchased(_upc);
    }

    function fetchItemBufferOne(uint _upc) public view returns
    (
        uint itemSKU,
        uint itemUPC,
        address ownerID,
        address originFarmerID,
        string memory originFarmName,
        string memory originFarmInformation,
        string memory originFarmLatitude,
        string memory originFarmLongitude
    )
    {
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        ownerID = items[_upc].ownerID;
        originFarmerID = items[_upc].originFarmerID;
        originFarmName = items[_upc].originFarmName;
        originFarmInformation = items[_upc].originFarmInformation;
        originFarmLatitude = items[_upc].originFarmLatitude;
        originFarmLongitude = items[_upc].originFarmLongitude;

        return
        (
        itemSKU,
        itemUPC,
        ownerID,
        originFarmerID,
        originFarmName,
        originFarmInformation,
        originFarmLatitude,
        originFarmLongitude
        );
    }

    function fetchItemBufferTwo(uint _upc) public view returns
    (
        uint itemSKU,
        uint itemUPC,
        uint productID,
        string memory productNotes,
        uint productPrice,
        uint itemState,
        address distributorID,
        address retailerID,
        address consumerID
    )
    {
        itemSKU = items[_upc].sku;
        itemUPC = items[_upc].upc;
        productID = items[_upc].productID;
        productNotes = items[_upc].productNotes;
        productPrice = items[_upc].productPrice;
        itemState = uint(items[_upc].itemState);
        distributorID = items[_upc].distributorID;
        retailerID = items[_upc].retailerID;
        consumerID = items[_upc].consumerID;

        return
        (
        itemSKU,
        itemUPC,
        productID,
        productNotes,
        productPrice,
        itemState,
        distributorID,
        retailerID,
        consumerID
        );
    }
}
