// SPDX-License-Identifier: Gpl-3.0

pragma solidity 0.8.10;

import "./TokenIntegration.sol";
import "forge-std/console.sol";

contract IdleAaveV3DAIIntegrationTest is IdleAaveV3TokenIntegrationTest {
    function _setUp() internal override {
        underlying = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
        aToken = 0x82E64f49Ed5EC1bC6e43DAD4FC8Af9bb3A2312EE;
        idleToken = IIdleTokenGovernance(
            0x8a999F5A3546F8243205b2c0eCb0627cC10003ab
        );
        pool = provider.getPool();

        amount = 1000 * 1e18;

        tokenWhale = DAI_WHALE;
    }
}
