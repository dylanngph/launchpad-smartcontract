// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISaleFactoryManager {
    function assignSaleToOwner(address _sale, address _owner) external;
}
