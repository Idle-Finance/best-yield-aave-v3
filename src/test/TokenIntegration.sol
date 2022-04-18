// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "../IdleAaveV3.sol";
import "../interfaces/idle/IIdleTokenGovernance.sol";

import "./utils/DSTestPlus.sol";
import "./utils/CheatCodes.sol";

import "forge-std/console.sol";

/// @title abstract contract for token integration test
/// @dev override `_setUp` function
abstract contract IdleAaveV3TokenIntegrationTest is DSTestPlus {
    address internal constant USDC_WHALE =
        0x51E3D44172868Acc60D68ca99591Ce4230bc75E0; // MEXC.com
    address internal constant DAI_WHALE =
        0x4A35582a710E1F4b2030A3F826DA20BfB6703C09;
    address internal constant WETH_WHALE =
        0x77ceea82E4362dD3B2E0D7F76d0A71A628Cad300;

    CheatCodes internal constant cheats =
        CheatCodes(0x7109709ECfa91a80626fF3989D68f67F5b1DD12D);

    uint256 internal constant POLYGON_MAINNET_CHIANID = 137;

    uint256 internal constant FULL_ALLOCATION = 100000;

    /// @notice aave v3 provider
    IPoolAddressesProvider internal constant provider =
        IPoolAddressesProvider(0xa97684ead0e402dC232d5A977953DF7ECBaB3CDb);

    IIdleTokenGovernance internal idleToken;
    IdleAaveV3 internal wrapper;

    /// @notice for example DAI

    address internal underlying;

    /// @notice for example aDAI
    address internal aToken;

    /// @notice fetched via aave v3 provider
    address internal pool;

    /// @notice token whale address
    address internal tokenWhale;

    /// @notice owner of idleAaveV3 wrapper contract
    address internal owner;

    /// @notice underlying amount to deposit
    uint256 internal amount;

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
        // set up tokens and a whale address
        _setUp();

        IIdleTokenGovernance _idleToken = idleToken;

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

        // fund
        cheats.prank(tokenWhale);
        IERC20(underlying).transfer(address(this), amount);

        // owner
        owner = _idleToken.owner();
        wrapper.transferOwnership(owner);

        // approve
        IERC20(underlying).approve(address(_idleToken), amount);
    }

    /// @dev set up tokens and a whale address
    ///      override this methods on the pararent contract
    function _setUp() internal virtual;

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
        idleToken.mintIdleToken(amount, false, address(0));

        assertEq(idleToken.balanceOf(address(this)), (amount * 1e18) / price);
        assertEq(IERC20(underlying).balanceOf(address(this)), 0);
    }

    function testRedeem()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
        setUpAllocations
    {
        uint256 mintedTokens = idleToken.mintIdleToken(
            amount,
            false,
            address(0)
        );
        cheats.roll(block.number + 1); // progress blockNumber
        idleToken.redeemIdleToken(mintedTokens);

        assertEq(idleToken.balanceOf(address(this)), 0, "idletoken_bal");
        assertApproxEq(
            IERC20(underlying).balanceOf(address(this)),
            amount,
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

        assertTrue(idleToken.rebalance()); // return true if rebalanced

        assertGe(idleToken.tokenPriceWithFee(address(this)), priceBefore);
        assertRelApproxEq(
            IERC20(aToken).balanceOf(address(idleToken)),
            (assetsInUnderlying * (100000 - maxUnlentPerc)) / 100000,
            1e12 // 1e18 = 100 %
        );
    }

    function testNextSupplyRate()
        external
        runOnForkingNetwork(POLYGON_MAINNET_CHIANID)
    {
        uint256 currentRate = wrapper.nextSupplyRate(0);
        uint256 nextRate = wrapper.nextSupplyRate(amount);

        assertApproxEq(nextRate, 1e18, 10 * 1e18); // 1~10
        assertLe(nextRate, currentRate, "the much supply,the lower rate");
    }
}
