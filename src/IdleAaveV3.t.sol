// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "forge-std/console.sol";

import "./IdleAaveV3.sol";
import "./test/mocks/MockERC20.sol";
import "./test/mocks/MockAToken.sol";
import "./test/mocks/PoolAddressesProviderMock.sol";
import "./test/mocks/PoolMock.sol";

import "./test/utils/DSTestPlus.sol";
import "./test/utils/CheatCodes.sol";

contract IdleAaveV3Test is DSTestPlus {
    CheatCodes internal constant cheats =
        CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

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
        wrapper.transferOwnership(owner);

        // fund
        MockERC20(underlying).mint(address(wrapper), 1e10);

        cheats.label(address(wrapper), "wrapper");
        cheats.label(address(underlying), "underlying");
    }

    function testOnlyIdleTokenCanMintOrRedeem() external {
        address caller = address(0xCAFE);

        hevm.prank(caller);
        cheats.expectRevert(bytes("wrapper/only-idle"));
        wrapper.mint();

        hevm.prank(caller);
        cheats.expectRevert(bytes("wrapper/only-idle"));
        wrapper.redeem(caller);
    }

    function testSetReferral() external {
        assertEq(wrapper.referralCode(), 0);

        hevm.prank(owner);
        wrapper.setReferralCode(10);
        assertEq(wrapper.referralCode(), 10);

        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
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

// contract IdleAaveV3TestOnForking is IdleAaveV3Test {
//     uint256 internal POLYGON_MAINNET_CHIANID = 137;

//     modifier runOnForkingNetwork(uint256 networkId) {
//         // solhint-disable-next-line
//         if (block.chainid == networkId) {
//             _;
//         }
//     }

//     function setUp() public override {
//         if (block.chainid != POLYGON_MAINNET_CHIANID) {
//             return super.setUp();
//         }

//         underlying = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC on Polygon
//         aToken = 0x625E7708f30cA75bfd92586e17077590C60eb4cD; // USDC-AToken-Polygon
//         provider = IPoolAddressesProvider(
//             0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
//         );
//         pool = provider.getPool();

//         wrapper = new IdleAaveV3(
//             address(underlying),
//             address(aToken),
//             address(this),
//             provider
//         );
//         wrapper.transferOwnership(owner);

//         // fund
//         cheats.prank(0x51E3D44172868Acc60D68ca99591Ce4230bc75E0); // MEXC.com
//         IERC20(underlying).transfer(address(wrapper), 1e10);

//         cheats.label(address(wrapper), "wrapper");
//         cheats.label(address(underlying), "underlying");
//         cheats.label(address(aToken), "aToken");
//         cheats.label(address(pool), "pool");
//     }

//     function testNextSupplyRate()
//         external
//         runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
//     {
//         uint256 rate = 0;
//         assertEq(wrapper.nextSupplyRate(1000 * 1e18), rate);
//     }
// }
