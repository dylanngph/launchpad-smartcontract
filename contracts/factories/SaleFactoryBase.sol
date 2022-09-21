// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";

contract SaleFactoryBase is Ownable, ReentrancyGuard {
    uint8 public saleType;
    address public implementation;
    address public feeTo;
    uint256 public fee;

    event SaleCreated(address indexed owner, address indexed sale, uint8 saleType, bytes32 salt);

    constructor(
        uint8 _saleType,
        address _implementation,
        uint256 _fee
    ) {
        saleType = _saleType;
        implementation = _implementation;
        feeTo = msg.sender;
        fee = _fee;
    }

    modifier enoughFee() {
        require(msg.value >= fee, "NOT_ENOUGH_FEE");
        _;
    }

    function clone(bytes32 salt) internal returns (address sale) {
        sale = Clones.cloneDeterministic(implementation, salt);
    }

    function predictAddress(bytes32 salt) public view returns (address sale) {
        sale = Clones.predictDeterministicAddress(implementation, salt, address(this));
    }

    function setSaleType(uint8 _saleType) external onlyOwner {
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
}
