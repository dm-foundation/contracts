
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "../src/store-reg.sol";

contract MyScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        uint256 store_id;
        // need to be the address of the PRIVATE_KEY
        address testAddress = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        // root hash for the store
        bytes32 rootHash = 0xf7da9dd69c40b660bedf17b0bafe9b16085e1bf34c6bc18655c5af3997aa5174;
        vm.startBroadcast(deployerPrivateKey);
        Store store = new Store("UAP", "UAP", "baseUri");
        store_id =  store.mintTo(testAddress, 0, rootHash);
        vm.stopBroadcast();
    }
}
