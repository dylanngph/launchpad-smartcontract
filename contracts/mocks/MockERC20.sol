//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockERC20 is ERC20 {
    uint8 private decimals_;

    constructor(string memory name, string memory symbol, uint8 _decimals) ERC20(name, symbol) {
        decimals_ = _decimals;
    }

    function decimals() public view override returns (uint8) {
        return decimals_;
    }


    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}
