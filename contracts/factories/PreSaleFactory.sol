// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SaleFactoryBase.sol";
import "@openzeppelin/contracts/proxy/Clones.sol";
import "../interfaces/IPreSale.sol";

contract PreSaleFactory is SaleFactoryBase {
    constructor(
        address _factoryManager,
        address _implementation,
        uint256 _fee
    ) SaleFactoryBase(_factoryManager, _implementation, _fee) {}

    function create(SaleDetail memory _saleDetail) external payable enoughFee nonReentrant returns (address sale) {
        refundExcessiveFee();
        payable(feeTo).transfer(fee);
        sale = Clones.clone(implementation);
        IPreSale(sale).initialize(_saleDetail);

        assignSaleToOwner(_saleDetail.owner, sale);

        emit SaleCreated(_saleDetail.owner, sale, saleType);

        return sale;
    }
}
