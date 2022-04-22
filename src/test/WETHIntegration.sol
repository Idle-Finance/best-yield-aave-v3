// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "./TokenIntegration.sol";

contract IdleAaveV3WETHIntegrationTest is IdleAaveV3TokenIntegrationTest {
    function _setUp() internal override {
        underlying = 0x7ceB23fD6bC0adD59E62ac25578270cFf1b9f619;
        aToken = 0xe50fA9b3c56FfB159cB0FCA61F5c9D750e8128c8;
        idleToken = IIdleTokenGovernance(
            0xfdA25D931258Df948ffecb66b5518299Df6527C4
        );
        pool = provider.getPool();

        amount = 100 * 1e18;
    }
}
