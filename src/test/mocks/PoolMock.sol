// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../../interfaces/aave-v3/DataTypes.sol";
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
        if (type(uint256).max == amount) {
            amount = MockAToken(aToken).balanceOf(msg.sender);
        }
        MockAToken(aToken).burn(asset, msg.sender, to, amount);
        return amount;
    }

    /**
     * @notice Returns the state and configuration of the reserve
     * @param asset The address of the underlying asset of the reserve
     * @return The state and configuration data of the reserve
     **/
    function getReserveData(address asset)
        external
        view
        returns (DataTypes.ReserveData memory)
    {
        revert("[must be implement]");
    }
}
