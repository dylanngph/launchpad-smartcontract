// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SaleFactoryBase.sol";
import "../interfaces/IPreSale.sol";

contract PreSaleFactory is SaleFactoryBase {
    constructor(
        uint8 _saleType,
        address _implementation,
        uint256 _fee
    ) SaleFactoryBase(_saleType, _implementation, _fee) {}

    function create(SaleDetail memory _saleDetail, bytes32 salt)
        external
        payable
        enoughFee
        nonReentrant
        returns (address sale)
    {
        refundExcessiveFee();
        payable(feeTo).transfer(fee);
        sale = clone(salt);
        IPreSale(sale).initialize(_saleDetail);

        emit SaleCreated(_saleDetail.owner, sale, saleType, salt);

        return sale;
    }
}
