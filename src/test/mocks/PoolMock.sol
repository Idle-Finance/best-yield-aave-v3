// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./MockAToken.sol";

contract PoolMock {
    using SafeERC20 for IERC20;

    mapping(address => address) internal underlyingToAToken;

    constructor(address uToken, address aToken) {
        underlyingToAToken[uToken] = aToken;
    }

    function supply(
        address asset,
        uint256 amount,
        address onBehalfOf,
        uint16 referralCode
    ) external {
        abi.encode(referralCode); // silence warning

        address aToken = underlyingToAToken[asset];

        IERC20(asset).safeTransferFrom(msg.sender, aToken, amount);
        MockERC20(aToken).mint(onBehalfOf, amount);
    }

    function withdraw(
        address asset,
        uint256 amount,
        address to
    ) external returns (uint256) {
        address aToken = underlyingToAToken[asset];

        MockAToken(aToken).burn(asset, msg.sender, to, amount);
    }
}
