// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableMap.sol";
import "../interfaces/ISaleFactoryBase.sol";

contract SaleFactoryManager is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;
    using EnumerableMap for EnumerableMap.UintToAddressMap;

    struct SaleWithType {
        uint8 saleType;
        address saleAddress;
    }

    Counters.Counter public saleTypeIdx;
    EnumerableSet.AddressSet private saleFactories;
    // mapping(address => EnumerableSet.AddressSet) private salesOfOwner;
    // mapping(address => EnumerableSet.AddressSet) private salesOfPurchaser;
    EnumerableSet.AddressSet private allSales;

    function addSaleFactory(address _saleFactory) public onlyOwner {
        require(!saleFactories.contains(_saleFactory), "FACTORY_ALREADY_EXISTED");
        saleFactories.add(_saleFactory);
        ISaleFactoryBase(_saleFactory).setSaleType(uint8(saleTypeIdx.current()));

        saleTypeIdx.increment();
    }

    function replaceSaleFactory(address _oldSaleFactory, address _newSaleFactory) public onlyOwner {
        require(saleFactories.contains(_oldSaleFactory), "OLD_FACTORY_NOT_EXIST");
        require(!saleFactories.contains(_newSaleFactory), "NEW_FACTORY_EXISTED");

        saleFactories.remove(_oldSaleFactory);

        saleFactories.add(_newSaleFactory);
        ISaleFactoryBase(_newSaleFactory).setSaleType(ISaleFactoryBase(_oldSaleFactory).saleType());
    }

    function removeSaleFactory(address _saleFactory) public onlyOwner {
        require(saleFactories.contains(_saleFactory), "FACTORY_NOT_EXIST");

        saleFactories.remove(_saleFactory);
    }

    // function getSalesOfOwner(address _owner) public view returns (address[] memory) {
    //     return salesOfOwner[_owner].values();
    // }

    // function updateSalesOfOwner(address _sale, address _owner) public {
    //     require(saleFactories.contains(msg.sender), "ONLY_FACTORY");

    //     salesOfOwner[_owner].add(_sale);
    //     allSales.add(_sale);
    // }

    // function getSalesOfPurchaser(address _purchaser) public view returns (address[] memory) {
    //     return salesOfPurchaser[_purchaser].values();
    // }

    // function updateSalesOfPurchaser(address _sale, address _purchaser) public {
    //     require(saleFactories.contains(msg.sender), "ONLY_FACTORY");

    //     salesOfPurchaser[_purchaser].add(_sale);
    //     allSales.add(_sale);
    // }

    function getSalesOfType(uint8 _saleType) public view returns (address[] memory) {
        address[] memory sales = new address[](allSales.length());
        uint256 idx = 0;
        for (uint256 i = 0; i < allSales.length(); i++) {
            if (ISaleFactoryBase(allSales.at(i)).saleType() == _saleType) {
                sales[idx] = allSales.at(i);
                idx++;
            }
        }

        return sales;
    }

    function getAllSales() public view returns (address[] memory) {
        return allSales.values();
    }

    function getAllSalesPaging(uint256 _page, uint256 _limit)
        public
        view
        returns (
            SaleWithType[] memory,
            uint256,
            uint256,
            uint256
        )
    {
        require(_page > 0, "PAGE_MUST_GREATER_THAN_0");
        uint256 length = allSales.length();
        uint256 totalPages = length / _limit + (length % _limit == 0 ? 0 : 1);
        _page = _page - 1;

        if (_page * _limit > length) {
            return (new SaleWithType[](0), 0, _limit, totalPages);
        }
        uint256 end = _page * _limit + _limit;
        if (end > length) {
            end = length;
        }
        SaleWithType[] memory saleAddresses = new SaleWithType[](end - _page * _limit);
        for (uint256 i = _page * _limit; i < end; i++) {
            saleAddresses[i - _page * _limit] = SaleWithType({
                saleType: ISaleFactoryBase(allSales.at(i)).saleType(),
                saleAddress: allSales.at(i)
            });
        }
        return (saleAddresses, _page, _limit, totalPages);
    }
}
