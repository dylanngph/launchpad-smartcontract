// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IRouter.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

struct SaleDetail {
    address owner;
    IRouter router;
    IERC20 token;
    bool buyInETH;
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
}

interface IPreSale {
    function initialize(SaleDetail memory _saleDetail) external;
}
