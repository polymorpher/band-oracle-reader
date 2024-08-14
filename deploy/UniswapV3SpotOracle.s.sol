// SPDX-License-Identifier: CC-BY-NC-4.0
pragma solidity =0.8.18;

import "forge-std/Script.sol";
import "forge-std/console.sol";
import "contracts/UniswapV3SpotOracle.sol";

contract UniswapV3SpotOracleDeployer is Script {
    function run() public {
        address deployer = vm.addr(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        vm.startBroadcast(deployer);
        address pool = vm.envAddress("POOL_ADDRESS");
        UniswapV3SpotOracle oracle = new UniswapV3SpotOracle(IUniswapV3Pool(pool), true, 0, deployer);
        int256 r = oracle.latestAnswer();
        console.log("Rate: %s", r);
        console.log("Oracle address: %s", address(oracle));
        vm.stopBroadcast();
    }
}