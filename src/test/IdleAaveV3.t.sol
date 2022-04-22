// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "../IdleAaveV3.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockAToken.sol";
import "./mocks/PoolAddressesProviderMock.sol";
import "./mocks/PoolMock.sol";

import "./utils/DSTestPlus.sol";

contract IdleAaveV3Test is DSTestPlus {
    IdleAaveV3 internal wrapper;
    address internal underlying;
    address internal aToken;
    address internal pool;
    IPoolAddressesProvider internal provider;

    address internal owner = address(0xBEEF);

    function setUp() public virtual {
        underlying = address(new MockERC20("", ""));
        aToken = address(new MockAToken("", ""));
        pool = address(new PoolMock(address(underlying), address(aToken)));
        provider = new PoolAddressesProviderMock(address(pool));

        wrapper = new IdleAaveV3(
            address(underlying),
            address(aToken),
            address(this),
            provider
        );

        // transfer ownership
        wrapper.transferOwnership(owner);

        // fund
        MockERC20(underlying).mint(address(wrapper), 1e10);

        //  label
        hevm.label(address(wrapper), "wrapper");
        hevm.label(address(underlying), "underlying");
    }

    function testConstructorParams() external {
        hevm.expectRevert(IdleAaveV3.IdleAaveV3_ZeroAddress.selector);
        new IdleAaveV3(address(0), address(aToken), address(this), provider);

        hevm.expectRevert(IdleAaveV3.IdleAaveV3_ZeroAddress.selector);
        new IdleAaveV3(underlying, address(0), address(this), provider);

        hevm.expectRevert(IdleAaveV3.IdleAaveV3_ZeroAddress.selector);
        new IdleAaveV3(
            address(underlying),
            address(aToken),
            address(0),
            provider
        );
    }

    function testOnlyIdleTokenCanMintOrRedeem() external {
        address caller = address(0xCAFE);

        hevm.prank(caller);
        hevm.expectRevert(IdleAaveV3.IdleAaveV3_OnlyIdleToken.selector);
        wrapper.mint();

        hevm.prank(caller);
        hevm.expectRevert(IdleAaveV3.IdleAaveV3_OnlyIdleToken.selector);
        wrapper.redeem(caller);
    }

    function testSetReferral() external {
        assertEq(wrapper.referralCode(), 0);

        hevm.prank(owner);
        wrapper.setReferralCode(10);
        assertEq(wrapper.referralCode(), 10);

        hevm.expectRevert(bytes("Ownable: caller is not the owner"));
        wrapper.setReferralCode(14);
        assertEq(wrapper.referralCode(), 10);
    }

    function testMint() external {
        wrapper.mint();

        assertEq(IERC20(underlying).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(aToken).balanceOf(address(this)), 1e10);
    }

    function testRedeem() external {
        wrapper.mint();

        IERC20(aToken).transfer(address(wrapper), 1e10);
        wrapper.redeem(address(this));

        assertEq(IERC20(aToken).balanceOf(address(wrapper)), 0);
        assertEq(IERC20(underlying).balanceOf(address(this)), 1e10);
    }

    function testAvailableLiquidity() external {
        uint256 liquidity = IERC20(underlying).balanceOf(aToken);
        assertEq(wrapper.availableLiquidity(), liquidity);
    }

    function testPrice() external {
        assertEq(wrapper.getPriceInToken(), 1e18); // fixed price
    }
}
