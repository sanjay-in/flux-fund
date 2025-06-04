// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.27;

import {Script} from "forge-std/Script.sol";
import {DecentralizedStableCoin} from "../src/DSC.sol";

contract DeployDSC is Script {
    function run() external returns (DecentralizedStableCoin) {
        vm.startBroadcast();
        DecentralizedStableCoin dsc = new DecentralizedStableCoin("DecentralizedCoin", "DSC");
        vm.stopBroadcast();
        return dsc;
    }
}