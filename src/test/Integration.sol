// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "forge-std/console.sol";

import "../interfaces/idle/IIdleTokenGovernance.sol";
import "../IdleAaveV3.sol";
import "../IdleAaveV3.t.sol";
import "./mocks/MockERC20.sol";
import "./mocks/MockAToken.sol";
import "./mocks/PoolAddressesProviderMock.sol";
import "./mocks/PoolMock.sol";

import "./utils/DSTestPlus.sol";
import "./utils/CheatCodes.sol";

contract IdleAaveV3IntegrationTest is DSTestPlus {
    uint256 internal constant POLYGON_MAINNET_CHIANID = 137;
    uint256 internal constant FULL_ALLOCATION = 100000;
    address internal constant USDC_WHALE =
        0x51E3D44172868Acc60D68ca99591Ce4230bc75E0; // MEXC.com

    CheatCodes internal constant cheats =
        CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    IIdleTokenGovernance internal idleToken;
    IdleAaveV3 internal wrapper;
    address internal underlying;
    address internal aToken;
    address internal pool;
    IPoolAddressesProvider internal provider;

    address internal owner;

    modifier runOnForkingNetwork(uint256 networkId) {
        // solhint-disable-next-line
        if (block.chainid == networkId) {
            _;
        }
    }
    modifier setUpAllocations() {
        IIdleTokenGovernance _idleToken = idleToken;

        // set new allocations
        address[] memory availableTokens = _idleToken.getAllAvailableTokens();
        uint256 length = availableTokens.length;

        {
            address[] memory protocolTokens = new address[](length + 1);
            address[] memory wrappers = new address[](length + 1);

            // create protocol tokens and wrappers parameters
            for (uint256 i = 0; i < length; i++) {
                protocolTokens[i] = availableTokens[i];
                wrappers[i] = _idleToken.protocolWrappers(availableTokens[i]);
            }
            protocolTokens[length] = aToken;
            wrappers[length] = address(wrapper);

            // create govTokens parameters
            address[] memory govTokens = new address[](1);
            address[] memory govTokensEqualLen = new address[](length + 1);
            govTokens[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
            govTokensEqualLen[0] = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
            govTokensEqualLen[1] = address(0);
            govTokensEqualLen[2] = address(0);

            // add aave-v3 wrapper
            cheats.prank(owner);
            _idleToken.setAllAvailableTokensAndWrappers(
                protocolTokens,
                wrappers,
                govTokens,
                govTokensEqualLen
            );
        }
        // set allocations
        uint256[] memory allocations = new uint256[](length + 1);
        uint256[] memory currentAllocations = _idleToken.getAllocations();
        allocations[length] = FULL_ALLOCATION;

        cheats.prank(owner);
        _idleToken.setAllocations(allocations);

        _;
    }

    function setUp() public runOnForkingNetwork(POLYGON_MAINNET_CHIANID) {
        underlying = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC on Polygon
        aToken = 0x625E7708f30cA75bfd92586e17077590C60eb4cD; // USDC-AToken-Polygon
        provider = IPoolAddressesProvider(
            0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb
        );

        IIdleTokenGovernance _idleToken = IIdleTokenGovernance(
            0x1ee6470CD75D5686d0b2b90C0305Fa46fb0C89A1
        ); // idleUSDC
        idleToken = _idleToken;

        pool = provider.getPool();

        wrapper = new IdleAaveV3(
            address(underlying),
            address(aToken),
            address(_idleToken),
            provider
        );

        // label
        cheats.label(address(_idleToken), "idleToken");
        cheats.label(address(wrapper), "wrapper");
        cheats.label(address(underlying), "underlying");
        cheats.label(address(aToken), "aToken");
        cheats.label(address(pool), "pool");

        // owner
        owner = _idleToken.owner();
        wrapper.transferOwnership(owner);

        // fund
        cheats.prank(USDC_WHALE);
        IERC20(underlying).transfer(address(this), 1e10);

        // approve
        IERC20(underlying).approve(address(_idleToken), 1e10);
    }

    function testSetReferral()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
    {
        hevm.prank(owner);
        wrapper.setReferralCode(10);
        assertEq(wrapper.referralCode(), 10);

        cheats.expectRevert(bytes("Ownable: caller is not the owner"));
        wrapper.setReferralCode(14);
        assertEq(wrapper.referralCode(), 10);
    }

    function testMint()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
        setUpAllocations
    {
        uint256 price = idleToken.tokenPriceWithFee(address(this));
        idleToken.mintIdleToken(1e10, false, address(0));

        assertEq(idleToken.balanceOf(address(this)), (1e10 * 1e18) / price);
        assertEq(IERC20(underlying).balanceOf(address(this)), 0);
    }

    function testRedeem()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
        setUpAllocations
    {
        uint256 mintedTokens = idleToken.mintIdleToken(1e10, false, address(0));
        cheats.roll(block.number + 1); // progress blockNumber
        idleToken.redeemIdleToken(mintedTokens);

        assertEq(idleToken.balanceOf(address(this)), 0, "idletoken_bal");
        assertApproxEq(
            IERC20(underlying).balanceOf(address(this)),
            1e10,
            1 // maxDelta
        );
    }

    function testRebalance()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
        setUpAllocations
    {
        uint256 priceBefore = idleToken.tokenPriceWithFee(address(this));
        uint256 assetsInUnderlying = (idleToken.totalSupply() * priceBefore) / 1e18; // prettier-ignore
        uint256 maxUnlentPerc = idleToken.maxUnlentPerc(); // 100000 == 100% -> 1000 == 1%

        assertBoolEq(idleToken.rebalance(), true); // return true if rebalanced

        assertGe(idleToken.tokenPriceWithFee(address(this)), priceBefore);
        assertRelApproxEq(
            IERC20(aToken).balanceOf(address(idleToken)),
            (assetsInUnderlying * (100000 - maxUnlentPerc)) / 100000,
            1e12 // 1e18 = 100 %
        );
    }

    // function testNextSupplyRate()
    //     external
    //     runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
    // {
    //     uint256 rate = 0;
    //     assertEq(wrapper.nextSupplyRate(1000 * 1e10), rate);
    // }
}
