// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/aave-v3/IReserveInterestRateStrategy.sol";

contract InterestRateStrategyMock is IReserveInterestRateStrategy {
    uint256 public borrowRate;
    uint256 public supplyRate;

    /**
     * @notice Returns the base variable borrow rate
     * @return The base variable borrow rate, expressed in ray
     **/
    function getBaseVariableBorrowRate() external view returns (uint256) {}

    /**
     * @notice Returns the maximum variable borrow rate
     * @return The maximum variable borrow rate, expressed in ray
     **/
    function getMaxVariableBorrowRate() external view returns (uint256) {}

    /**
     * @notice Calculates the interest rates depending on the reserve's state and configurations
     * @param params The parameters needed to calculate interest rates
     * @return liquidityRate The liquidity rate expressed in rays
     * @return stableBorrowRate The stable borrow rate expressed in rays
     * @return variableBorrowRate The variable borrow rate expressed in rays
     **/
    function calculateInterestRates(
        DataTypes.CalculateInterestRatesParams memory params
    )
        external
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {}

    // mocked methods
    function setSupplyRate(uint256 _supplyRate) external {
        supplyRate = _supplyRate;
    }

    function setBorrowRate(uint256 _borrowRate) external {
        borrowRate = _borrowRate;
    }
}
