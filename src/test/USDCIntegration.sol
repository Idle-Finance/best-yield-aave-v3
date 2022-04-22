// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "./TokenIntegration.sol";

contract IdleAaveV3USDCIntegrationTest is IdleAaveV3TokenIntegrationTest {
    function _setUp() internal override {
        underlying = 0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174; // USDC on Polygon
        aToken = 0x625E7708f30cA75bfd92586e17077590C60eb4cD; // USDC-AToken-Polygon
        idleToken = IIdleTokenGovernance(
            0x1ee6470CD75D5686d0b2b90C0305Fa46fb0C89A1
        );
        pool = provider.getPool();

        amount = 1e10;
    }
}
