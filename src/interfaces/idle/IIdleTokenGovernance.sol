// SPDX-License-Identifier: AGPL-3.0

pragma solidity ^0.8.0;
import "./IIdleTokenV4.sol";

interface IIdleTokenGovernance is IIdleTokenV4 {
    function maxUnlentPerc() external view returns (uint256);

    function token() external view returns (address);

    function owner() external view returns (address);

    function rebalancer() external view returns (address);

    function protocolWrappers(address) external view returns (address);

    function oracle() external view returns (address);

    function tokenPrice() external view returns (uint256 price);

    function tokenDecimals() external view returns (uint256 decimals);

    function getAPRs()
        external
        view
        returns (address[] memory addresses, uint256[] memory aprs);

    function getAllocations() external view returns (uint256[] memory);

    function getGovTokens() external view returns (address[] memory);

    function getAllAvailableTokens() external view returns (address[] memory);

    function getProtocolTokenToGov(address _protocolToken)
        external
        view
        returns (address);

    function rebalance() external returns (bool);

    /**
     * Used by Rebalancer to set the new allocations
     *
     * @param _allocations : array with allocations in percentages (100% => 100000)
     */
    function setAllocations(uint256[] calldata _allocations) external;

    /**
     * It allows owner to modify allAvailableTokens array in case of emergency
     * ie if a bug on a interest bearing token is discovered and reset protocolWrappers
     * associated with those tokens.
     *
     * @param protocolTokens : array of protocolTokens addresses (eg [cDAI, iDAI, ...])
     * @param wrappers : array of wrapper addresses (eg [IdleCompound, IdleFulcrum, ...])
     * @param _newGovTokens : array of governance token addresses
     * @param _newGovTokensEqualLen : array of governance token addresses for each
     *  protocolToken (addr0 should be used for protocols with no govToken)
     */
    function setAllAvailableTokensAndWrappers(
        address[] calldata protocolTokens,
        address[] calldata wrappers,
        address[] calldata _newGovTokens,
        address[] calldata _newGovTokensEqualLen
    ) external;
}
