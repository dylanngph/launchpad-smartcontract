// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../interfaces/ISaleFactoryManager.sol";

contract SaleFactoryBase is Ownable, ReentrancyGuard {
    address public saleFactoryManager;
    uint8 public saleType;
    address public implementation;
    address public feeTo;
    uint256 public fee;

    event SaleCreated(address indexed owner, address indexed sale, uint8 saleType);

    constructor(
        address _factoryManager,
        address _implementation,
        uint256 _fee
    ) {
        saleFactoryManager = _factoryManager;
        implementation = _implementation;
        feeTo = msg.sender;
        fee = _fee;
    }

    modifier enoughFee() {
        require(msg.value >= fee, "NOT_ENOUGH_FEE");
        _;
    }

    modifier onlyManager() {
        require(msg.sender == saleFactoryManager, "ONLY_MANAGER");
        _;
    }

    function setSaleType(uint8 _saleType) external onlyManager {
        saleType = _saleType;
    }

    function setImplementation(address _implementation) external onlyOwner {
        implementation = _implementation;
    }

    function setFeeTo(address _feeTo) external onlyOwner {
        feeTo = _feeTo;
    }

    function setFee(uint256 _fee) external onlyOwner {
        fee = _fee;
    }

    function refundExcessiveFee() internal {
        uint256 refund = msg.value - fee;
        if (refund > 0) {
            payable(msg.sender).transfer(refund);
        }
    }

    function assignSaleToOwner(address _owner, address _sale) internal {
        ISaleFactoryManager(saleFactoryManager).assignSaleToOwner(_owner, _sale);
    }
}
