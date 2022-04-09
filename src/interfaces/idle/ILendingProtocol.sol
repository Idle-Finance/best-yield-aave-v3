// SPDX-License-Identifier: Gpl-3.0

pragma solidity ^0.8.0;

interface ILendingProtocol {
    function mint() external returns (uint256);

    function redeem(address account) external returns (uint256);

    function nextSupplyRate(uint256 amount) external view returns (uint256);

    function getAPR() external view returns (uint256);

    function getPriceInToken() external view returns (uint256);

    function token() external view returns (address);

    function underlying() external view returns (address);

    function availableLiquidity() external view returns (uint256);
}
