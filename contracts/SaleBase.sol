// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "@openzeppelin/contracts/utils/structs/EnumerableSet.sol";
import "./interfaces/ISaleFactoryBase.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

contract SaleBase is OwnableUpgradeable {
    using EnumerableSet for EnumerableSet.AddressSet;

    EnumerableSet.AddressSet private participants;
    address public saleFactory;

    function addParticipant(address _participant) public {
        participants.add(_participant);
    }

    function removeParticipant(address _participant) public {
        participants.remove(_participant);
    }

    function getParticipants() public view returns (address[] memory) {
        return participants.values();
    }

    function isParticipant(address _participant) public view returns (bool) {
        return participants.contains(_participant);
    }

    function getSaleType() public view returns (uint8) {
        return ISaleFactoryBase(saleFactory).saleType();
    }
}
