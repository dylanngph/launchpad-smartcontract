// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "../interfaces/ISaleFactoryBase.sol";

contract SaleFactoryManager is Ownable {
    using Counters for Counters.Counter;
    using EnumerableSet for EnumerableSet.AddressSet;

    Counters.Counter saleTypeIdx;
    EnumerableSet.AddressSet private saleFactories;
    mapping(address => address[]) salesOf;
    address[] public sales;

    function addSaleFactory(address _saleFactory) public onlyOwner {
        saleFactories.add(_saleFactory);
        ISaleFactoryBase(_saleFactory).setSaleType(uint8(saleTypeIdx.current()));

        saleTypeIdx.increment();
    }

    function addSaleFactories(address[] calldata _saleFactories) public onlyOwner {
        for (uint256 i = 0; i < _saleFactories.length; i++) {
            addSaleFactory(_saleFactories[i]);
        }
    }

    function replaceSaleFactory(address _oldSaleFactory, address _newSaleFactory) public onlyOwner {
        require(saleFactories.contains(_oldSaleFactory), "OLD_FACTORY_NOT_EXIST");
        require(!saleFactories.contains(_newSaleFactory), "NEW_FACTORY_EXIST");

        saleFactories.remove(_oldSaleFactory);

        saleFactories.add(_newSaleFactory);
        ISaleFactoryBase(_newSaleFactory).setSaleType(ISaleFactoryBase(_oldSaleFactory).saleType());
    }

    function removeSaleFactory(address _saleFactory) public onlyOwner {
        require(saleFactories.contains(_saleFactory), "FACTORY_NOT_EXIST");

        saleFactories.remove(_saleFactory);
    }

    function assignSaleToOwner(address _sale, address _owner) public {
        require(saleFactories.contains(msg.sender), "ONLY_FACTORY");

        salesOf[_owner].push(_sale);
        sales.push(_sale);
    }

    function getSalesOfType(address owner, uint8 saleType) public view returns (address[] memory) {
        uint256 length = 0;
        for (uint256 i = 0; i < salesOf[owner].length; i++) {
            if (ISaleFactoryBase(salesOf[owner][i]).saleType() == saleType) {
                length++;
            }
        }
        address[] memory saleAddresses = new address[](length);
        if (length == 0) {
            return saleAddresses;
        }
        uint256 currentIndex;
        for (uint256 i = 0; i < salesOf[owner].length; i++) {
            if (ISaleFactoryBase(salesOf[owner][i]).saleType() == saleType) {
                saleAddresses[currentIndex] = salesOf[owner][i];
                currentIndex++;
            }
        }
        return saleAddresses;
    }

    function getSales(address owner) public view returns (address[] memory) {
        return salesOf[owner];
    }

    function getAllSales() public view returns (address[] memory) {
        return sales;
    }

    function getAllSalesPaging(uint256 _page, uint256 _limit)
        public
        view
        returns (
            address[] memory,
            uint256,
            uint256
        )
    {
        uint256 length = sales.length;
        uint256 totalPages = length / _limit + (length % _limit == 0 ? 0 : 1);

        if (_page * _limit > length) {
            return (new address[](0), 0, totalPages);
        }
        uint256 end = _page * _limit + _limit;
        if (end > length) {
            end = length;
        }
        address[] memory saleAddresses = new address[](end - _page * _limit);
        for (uint256 i = _page * _limit; i < end; i++) {
            saleAddresses[i - _page * _limit] = sales[i];
        }
        return (saleAddresses, _page, totalPages);
    }
}
