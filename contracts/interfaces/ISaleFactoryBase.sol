// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISaleFactoryBase {
    function saleType() external view returns (uint8);

    function setSaleType(uint8 _saleType) external;
}
