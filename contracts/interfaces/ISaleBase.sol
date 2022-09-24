// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface ISaleBase {
    function addParticipant(address _participant) external;

    function removeParticipant(address _participant) external;

    function getParticipants() external view returns (address[] memory);

    function isParticipant(address _participant) external view returns (bool);

    function getSaleType() external view returns (uint8);

    function owner() external view returns (address);
}
