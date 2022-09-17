// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct SaleDetail {
    address owner;
    address feeTo;
    IRouter router;
    IERC20 token;
    bool isQuoteETH;
    uint256 price;
    uint256 listingPrice;
    uint256 minPurchase;
    uint256 maxPurchase;
    uint256 startTime;
    uint256 endTime;
    uint256 lpPercent;
    uint256 softCap;
    uint256 hardCap;
    uint256[] vestingTimes;
    uint256[] vestingPercents;
    bool isAutoListing;
    uint256 baseFee;
    uint256 tokenFee;
}

interface IPreSale {
    function initialize(SaleDetail memory _saleDetail) external;
}
