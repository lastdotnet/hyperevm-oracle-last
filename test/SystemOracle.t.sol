// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/Aggregator.sol";
import "../src/mocks/MockSystemOracle.sol";

contract SystemOracleTest is Test {
    Aggregator public aggregator;
    MockSystemOracle public mockOracle;
    address public owner;

    function setUp() public {
        owner = address(this);
        mockOracle = new MockSystemOracle();

        bytes memory code = address(mockOracle).code;

        vm.etch(address(mockOracle), "");

        vm.etch(address(0x1111111111111111111111111111111111111111), code);

        mockOracle = MockSystemOracle(0x1111111111111111111111111111111111111111);

        aggregator = new Aggregator();

        uint256[] memory prices = new uint256[](100);
        prices[0] = 1000e6; // $1000
        prices[1] = 2000e6; // $2000
        prices[2] = 3000e6; // $3000
        mockOracle.setOraclePxs(prices);
    }

    /// @notice
    /// TO-DO: fix decimal scaling issues
    function testPerpOracleIntegration() public {
        address asset = makeAddr("asset");
        uint32 metaIndex = 1;
        uint32 metaDecimals = 6;

        aggregator.setAsset(asset, true, metaIndex, metaDecimals, 0, false);

        uint256 price = aggregator.getPrice(asset);
        //scale to 8 decimals and remove decimals from systemOracle
        //https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/evm/system-contract
        uint256 expectedPrice = 2000e6 * (1e8) / (10 ** (6 - metaDecimals));
        assertEq(price, expectedPrice);
    }

    function testDifferentDecimalConfigurations() public {
        address asset1 = makeAddr("asset1");
        address asset2 = makeAddr("asset2");

        aggregator.setAsset(asset1, true, 0, 6, 0, false);
        aggregator.setAsset(asset2, true, 1, 6, 0, false);

        uint256 price1 = aggregator.getPrice(asset1);
        uint256 price2 = aggregator.getPrice(asset2);

        uint256 expectedPrice1 = 1000e6 * (1e8) / (10 ** (6 - 6));
        uint256 expectedPrice2 = 2000e6 * (1e8) / (10 ** (6 - 6));
        assertEq(price1, expectedPrice1);
        assertEq(price2, expectedPrice2);
    }
}
