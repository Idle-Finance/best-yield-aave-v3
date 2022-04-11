// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../interfaces/aave-v3/IPoolAddressesProvider.sol";

contract PoolAddressesProviderMock is IPoolAddressesProvider {
    address internal pool;

    constructor(address _pool) {
        pool = _pool;
    }

    function getPool() public view returns (address) {
        return pool;
    }
}
