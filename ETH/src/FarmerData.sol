// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

contract FarmerSupplyChain {
    enum CropStatus {
        Pending,
        Approved,
        Rejected,
        Sold
    }

    struct Crop {
        uint256 id;
        address farmer;
        string name;
        string pesticidesUsed;
        string fertilizersUsed;
        CropStatus status;
        uint256 price;
        address buyer;
    }

    struct User {
        address userAddress;
        string role; // "Farmer", "Inspector", "Customer"
        uint256 reputation;
    }

    address public admin;
    uint256 public cropCount;
    mapping(address => User) public users;
    mapping(uint256 => Crop) public crops;

    event CropRegistered(uint256 indexed cropId, address farmer);
    event CropReviewed(uint256 indexed cropId, CropStatus status);
    event CropSold(uint256 indexed cropId, address buyer);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not an admin");
        _;
    }

    modifier onlyInspector() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256("Inspector"), "Not an inspector");
        _;
    }

    modifier onlyFarmer() {
        require(keccak256(bytes(users[msg.sender].role)) == keccak256("Farmer"), "Not a farmer");
        _;
    }

    constructor() {
        admin = msg.sender;
    }

    function registerUser(string memory _role) public {
        require(bytes(users[msg.sender].role).length == 0, "Already registered");
        users[msg.sender] = User(msg.sender, _role, 0);
    }

    function registerCrop(
        string memory _name,
        string memory _pesticidesUsed,
        string memory _fertilizersUsed,
        uint256 _price
    ) public onlyFarmer {
        cropCount++;
        crops[cropCount] = Crop(
            cropCount, msg.sender, _name, _pesticidesUsed, _fertilizersUsed, CropStatus.Pending, _price, address(0)
        );
        emit CropRegistered(cropCount, msg.sender);
    }

    function reviewCrop(uint256 _cropId, bool _approved) public onlyInspector {
        require(crops[_cropId].status == CropStatus.Pending, "Already reviewed");
        crops[_cropId].status = _approved ? CropStatus.Approved : CropStatus.Rejected;
        emit CropReviewed(_cropId, crops[_cropId].status);
    }

    function buyCrop(uint256 _cropId) public payable {
        Crop storage crop = crops[_cropId];
        require(crop.status == CropStatus.Approved, "Crop not available for sale");
        require(msg.value == crop.price, "Incorrect price");

        crop.buyer = msg.sender;
        crop.status = CropStatus.Sold;
        payable(crop.farmer).transfer(msg.value);

        emit CropSold(_cropId, msg.sender);
    }
}
