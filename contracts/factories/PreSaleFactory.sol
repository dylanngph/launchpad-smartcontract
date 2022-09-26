// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./SaleFactoryBase.sol";
import "../interfaces/IPreSale.sol";

contract PreSaleFactory is SaleFactoryBase {
    address public bionLock;

    constructor(
        uint8 _saleType,
        address _implementation,
        uint256 _fee,
        address _bionLock
    ) SaleFactoryBase(_saleType, _implementation, _fee) {
        bionLock = _bionLock;
    }

    function setBionLock(address _bionLock) external onlyOwner {
        bionLock = _bionLock;
    }

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

        IPreSale(sale).initialize(_saleDetail, bionLock);

        IERC20(_saleDetail.token).transferFrom(msg.sender, sale, IPreSale(sale).calcTotalTokensRequired());

        emit SaleCreated(_saleDetail.owner, sale, saleType, salt);

        return sale;
    }
}
