// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";
import "../src/store-reg.sol";

contract StoreTest is Test {
    using stdStorage for StdStorage;

    Store private store;
    bytes32 testHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a;

    function setUp() public {
        // Deploy NFT contract
        store = new Store("STORES", "TUT", "baseUri");
    }

    function testFailMintToZeroAddress() public {
        store.mintTo(address(0), 0, testHash);
    }

    function testNewMintOwnerRegistered() public {
        uint256 id = store.mintTo(address(1), 1, testHash);
        uint256 slotOfNewOwner = stdstore
            .target(address(store))
            .sig(store.ownerOf.selector)
            .with_key(id)
            .find();

        uint160 ownerOfTokenIdOne = uint160(
            uint256(
                (vm.load(address(store), bytes32(abi.encode(slotOfNewOwner))))
            )
        );
        assertEq(address(ownerOfTokenIdOne), address(1));
    }

    function testBalanceIncremented() public {
        store.mintTo(address(1), 2, testHash);
        uint256 slotBalance = stdstore
            .target(address(store))
            .sig(store.balanceOf.selector)
            .with_key(address(1))
            .find();

        uint256 balanceFirstMint = uint256(
            vm.load(address(store), bytes32(slotBalance))
        );
        assertEq(balanceFirstMint, 1);

        store.mintTo(address(1), 3, testHash);
        uint256 balanceSecondMint = uint256(
            vm.load(address(store), bytes32(slotBalance))
        );
        assertEq(balanceSecondMint, 2);
    }

    function testSafeContractReceiver() public {
        Receiver receiver = new Receiver();
        store.mintTo(address(receiver), 4, testHash);
        uint256 slotBalance = stdstore
            .target(address(store))
            .sig(store.balanceOf.selector)
            .with_key(address(receiver))
            .find();

        uint256 balance = uint256(vm.load(address(store), bytes32(slotBalance)));
        assertEq(balance, 1);
    }

    function testFailUnSafeContractReceiver() public {
        vm.etch(address(1), bytes("mock code"));
        store.mintTo(address(1), 5, testHash);
    }
}

contract Receiver is IERC721Receiver {
    function onERC721Received(
        address operator,
        address from,
        uint256 id,
        bytes calldata data
    ) external override pure returns (bytes4) {
        return this.onERC721Received.selector;
    }
}


