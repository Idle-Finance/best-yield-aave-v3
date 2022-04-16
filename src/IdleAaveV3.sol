// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

import "./interfaces/idle/ILendingProtocol.sol";
import "./interfaces/aave-v3/IPool.sol";
import "./interfaces/aave-v3/IPoolAddressesProvider.sol";
import "./interfaces/aave-v3/IReserveInterestRateStrategy.sol";
import "./interfaces/aave-v3/IStableDebtToken.sol";
import "./interfaces/aave-v3/IVariableDebtToken.sol";
import "./interfaces/aave-v3/DataTypes.sol";

import "./lib/ReserveConfiguration.sol";

contract IdleAaveV3 is ILendingProtocol, Ownable {
    using ReserveConfiguration for DataTypes.ReserveConfigurationMap;
    using SafeERC20 for IERC20;

    error IdleAaveV3_ZeroAddress();

    error IdleAaveV3_OnlyIdleToken();

    uint256 private constant SCALE = 1e18;

    /// @notice aave v3 pool address provider
    IPoolAddressesProvider public immutable provider;

    /// @notice protocol token (aToken) address
    address public token;

    /// @notice underlying token (token eg DAI) address
    address public underlying;

    /// @notice idle interest-bearing token
    address public idleToken;

    /// @notice referral code for aave v3
    uint16 public referralCode;

    constructor(
        address _underlying,
        address _token,
        address _idleToken,
        IPoolAddressesProvider _provider
    ) {
        if (
            _underlying == address(0) ||
            _token == address(0) ||
            _idleToken == address(0) ||
            address(_provider) == address(0)
        ) revert IdleAaveV3_ZeroAddress();

        underlying = _underlying;
        token = _token;
        idleToken = _idleToken;
        provider = _provider;
    }

    /**
     * Throws if called by any account other than IdleToken contract.
     */
    modifier onlyIdle() {
        if (msg.sender != idleToken) revert IdleAaveV3_OnlyIdleToken();
        _;
    }

    function setReferralCode(uint16 _code) external onlyOwner {
        referralCode = _code;
    }

    /**
     * Not used
     */
    function nextSupplyRateWithParams(uint256[] calldata)
        external
        view
        returns (uint256)
    {
        return 0;
    }

    /**
     * Calculate next supply rate for Aave, given an `_amount` supplied
     *
     * @return : yearly net rate
     */
    function nextSupplyRate(uint256 _amount)
        external
        view
        override
        returns (uint256)
    {
        DataTypes.ReserveData memory data = IPool(
            provider.getPool()
        ).getReserveData(underlying); // prettier-ignore
        DataTypes.ReserveConfigurationMap memory config = data.configuration;
        uint256 reserveFactor = config.getReserveFactor();

        (uint256 totalStableDebt, uint256 avgStableRate) = IStableDebtToken(
            data.stableDebtTokenAddress
        ).getTotalSupplyAndAvgRate();

        uint256 totalVariableDebt = (IVariableDebtToken(
            data.variableDebtTokenAddress
        ).scaledTotalSupply() * data.variableBorrowIndex) / 10**27; // variable borrow index. Expressed in ray

        IReserveInterestRateStrategy rateStrategy = IReserveInterestRateStrategy(
                data.interestRateStrategyAddress
            );

        (uint256 liquidityRate, , ) = rateStrategy.calculateInterestRates(
            DataTypes.CalculateInterestRatesParams({
                unbacked: data.unbacked,
                liquidityAdded: _amount,
                liquidityTaken: 0,
                totalStableDebt: totalStableDebt,
                totalVariableDebt: totalVariableDebt,
                averageStableBorrowRate: avgStableRate,
                reserveFactor: reserveFactor,
                reserve: underlying,
                aToken: token
            })
        );
        return liquidityRate / 10**7; // 100 / 10**9 = 19**7
    }

    /**
     * @return current price of aToken in underlying, Aave price is always 1
     */
    function getPriceInToken() external view override returns (uint256) {
        return SCALE;
    }

    /**
     * @return apr : current yearly net rate
     */
    function getAPR() external view override returns (uint256) {
        // data.currentLiquidityRate means current supply rate. Expressed in ray
        DataTypes.ReserveData memory data = IPool(provider.getPool())
            .getReserveData(underlying);
        return uint256(data.currentLiquidityRate) / 10**7; // 100 / 10**9 = 10**7
    }

    /**
     * Gets all underlying tokens in this contract and mints aTokens
     * tokens are then transferred to msg.sender
     * NOTE: underlying tokens needs to be sent here before calling this
     * NOTE: given that aToken price is always 1 token -> underlying.balanceOf(this) == token.balanceOf(this)
     *
     * @return tokens : aTokens minted
     */
    function mint() external override onlyIdle returns (uint256 tokens) {
        IERC20 _uToken = IERC20(underlying);
        address pool = provider.getPool();

        // x underlying => x aTokens
        tokens = _uToken.balanceOf(address(this));
        _uToken.safeApprove(pool, tokens);
        // msg.sender will receive the aTokens
        IPool(pool).supply(address(_uToken), tokens, msg.sender, referralCode);
    }

    /**
     * Gets all aTokens in this contract and redeems underlying tokens.
     * underlying tokens are then transferred to `_account`
     * NOTE: aTokens needs to be sent here before calling this
     *
     * @return tokens : underlying tokens redeemd
     */
    function redeem(address _account)
        external
        override
        onlyIdle
        returns (uint256 tokens)
    {
        tokens = IERC20(token).balanceOf(address(this));
        // msg.sender will receive the underlying
        IPool(provider.getPool()).withdraw(underlying, tokens, _account);
    }

    /**
     * Get the underlying balance on the lending protocol
     *
     * @return underlying tokens available
     */
    function availableLiquidity() external view override returns (uint256) {
        return IERC20(underlying).balanceOf(token);
    }
}
