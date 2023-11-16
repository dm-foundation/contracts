// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

/// @title Sweeps ERC20's from the payment address to the merchants address
contract SweepERC20Payment {
    constructor (
        address payable merchant,
        address payable proof,
        uint256 amount,
        ERC20 erc20,
        address factory
    ) payable {
        require(msg.sender == factory);
        // if we are transfering ether
        uint256 balance = erc20.balanceOf(address(this));
        // not enough was sent so return what we have
        if (balance < amount) {
            erc20.transfer(proof, balance);
        } else {
            if (balance > amount) {
                // to much was sent so send the over payed amount back
                erc20.transfer(proof, balance - amount);
            }
            // pay the mechant
            erc20.transfer(merchant, amount);
        }
        // need to prevent solidity from returning code
        assembly {
            stop()
        }
    }
}

/// @title Sweeps ether from the payment address to the merchants address
contract SweepEtherPayment {
    constructor (
        address payable merchant,
        address payable proof,
        uint256 amount,
        address factory
    ) payable {
        // we need to commit to the factory or anyone could deploy this sweep contracts
        // commiting allows the reciepts to have a single souce of truth
        require(msg.sender == factory);
        // if we are transfering ether
        uint256 balance = address(this).balance;
        if (balance < amount) {
            proof.transfer(balance);
        } else {
            if (balance > amount) {
                // to much was sent so send the over payed amount back
                proof.transfer(balance - amount);
            }
            // pay the mechant
            merchant.transfer(amount);
        }
        // need to prevent solidity from returning code
        assembly {
            stop()
        }
    }
}

/// @title Provides functions around payments addresses
contract PaymentFactory {
    address lastPaymentAddress;

    function getBytecode(
        address merchant,
        address proof,
        uint256 amount,
        address currency
    ) public view returns (bytes memory) {
        bytes memory bytecode;
        if (currency == address(0)) {
            bytecode = type(SweepEtherPayment).creationCode;
            return abi.encodePacked(bytecode, abi.encode(merchant, proof, amount, address(this)));
        } else {
            bytecode = type(SweepERC20Payment).creationCode;
            return abi.encodePacked(bytecode, abi.encode(merchant, proof, amount, currency, address(this)));
        }
    }


    /// @notice Calulates the payament address given the following parameters
    /// @param merchant The merchant's address which the funds get sent to
    /// @param proof The address that the receipt or the refund will be sent to
    /// @param amount The amount the customer is paying
    /// @param currency The address of the ERC20 that is being used as payement. If that currency is Ether then use zero address `0x0000000000000000000000000000000000000000`.
    /// @param recieptHash The hash of the receipt used as salt for CREATE2
    /// @return The payment address
    function getPaymentAddress(
        address merchant,
        address proof,
        uint256 amount,
        address currency,
        bytes32 recieptHash
    ) public view returns (address)  {
        bytes32 hash = keccak256(
            abi.encodePacked(bytes1(0xff),
                             address(this),
                             recieptHash, // salt
                             keccak256(
                                 getBytecode(
                                     merchant, 
                                     proof, 
                                     amount,
                                     currency
                             ))));

                             // NOTE: cast last 20 bytes of hash to address
                             return address(uint160(uint(hash)));
    }


    /// @notice Given the parameters used to generate a payement address, this function will forward the payment to the merchant's address.
    /// @param merchant The merchant's address which the funds get sent to
    /// @param proof The address that the receipt or the refund will be sent to
    /// @param amount The amount the customer is paying
    /// @param currency The address of the ERC20 that is being used as payement. If that currency is Ether then use zero address `0x0000000000000000000000000000000000000000`.
    /// @param recieptHash The hash of the receipt
    function processPayment(
        address payable merchant,
        address payable proof,
        uint256 amount,
        address currency,
        bytes32 recieptHash
    ) public {
        address paymentContract;
        // if we are dealing with ether
        if (currency == address(0)) {
            paymentContract  = address(new SweepEtherPayment{salt: recieptHash}(merchant, proof, amount, address(this)));
        } else {
            paymentContract  = address(new SweepERC20Payment{salt: recieptHash}(merchant, proof, amount, ERC20(currency), address(this)));
        }
    }

    /// @notice this does a batched call to `processPayment`
    /// @param merchants The merchant's address which the funds get sent to
    /// @param proofs The address that the receipt or the refund will be sent to
    /// @param amounts The amount the customer is paying
    /// @param currencys The address of the ERC20 that is being used as payement. If that currency is Ether then use zero address `0x0000000000000000000000000000000000000000`.
    /// @param recieptHashes The hash of the receipt
    function batch(
        address payable[] calldata merchants,
        address payable[] calldata proofs,
        uint256[] calldata amounts,
        address[] calldata currencys,
        bytes32[] calldata recieptHashes
    ) public {
        for (uint i=0; i<merchants.length; i++) {
            processPayment(merchants[i], proofs[i], amounts[i], currencys[i], recieptHashes[i]);
        }
    }
}
