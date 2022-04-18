// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "./TokenIntegration.sol";
import "forge-std/console.sol";

contract IdleAaveV3DAIIntegrationTest is IdleAaveV3TokenIntegrationTest {
    function _setUp() internal override {
        underlying = 0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1;
        aToken = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
        idleToken = IIdleTokenGovernance(
            0x8a999F5A3546F8243205b2c0eCb0627cC10003ab
        );
        pool = provider.getPool();

        amount = 1000 * 1e18;

        tokenWhale = DAI_WHALE;
    }
}
