// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MockERC20.sol";

contract MockAToken is MockERC20 {
    using SafeERC20 for IERC20;

    constructor(string memory name, string memory symbol)
        MockERC20(name, symbol)
    {}

    function burn(
        address asset,
        address account,
        address to,
        uint256 amount
    ) external {
        _burn(account, amount);
        IERC20(asset).safeTransfer(to, amount);
    }
}
