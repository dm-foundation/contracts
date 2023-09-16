// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/Vm.sol";
import "../src/payment-factory.sol";

contract Payments is Test {
    PaymentFactory private factory;
    address generatedAddress;

    address payable merchant = payable(address(21));
    address currency = address(0);
    uint256 amount   = 5;
    // just a random hash
    bytes32 recieptHash = 0x5049705e4c047d2cfeb1050cffe847c85a8dbd96e7f129a3a1007920d9c61d9a; 
    address payable proof  = payable(address(23));

    function setUp() public {
        factory = new PaymentFactory();
        generatedAddress = factory.getPaymentAddress(
            merchant,
            proof,
            amount,
            currency,
            recieptHash
        );
    }

    function test_ProcessPayment() public {
        deal(generatedAddress, amount);
        factory.processPayment(
            merchant,
            proof,
            amount,
            currency,
            recieptHash
        );
        assertEq(merchant.balance, amount, "the payout contract should send the corret amount");
    }

    function test_UnderPayment() public {
        deal(generatedAddress, amount - 1);
        factory.processPayment(
            merchant,
            proof,
            amount,
            currency,
            recieptHash
        );
        assertEq(proof.balance, amount - 1, "the payout contract should return the ether if not enought was payed");
    }

    function test_OverPayment() public {
        deal(generatedAddress, amount + 1);
        deal(proof, 0);
        deal(merchant, 0);

        factory.processPayment(
            merchant,
            proof,
            amount,
            currency,
            recieptHash
        );
        assertEq(proof.balance, 1 , "the payout contract should return the ether if not enought was payed");
        assertEq(merchant.balance, amount, "the payout contract should send the corret amount");
    }
}
