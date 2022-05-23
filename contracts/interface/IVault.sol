// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface IVault {

    event TransferFunds(address to, uint amount);
	
    event TransactionCreated(
        address from,
        address to,
        uint amount,
        uint transactionId
        );

    event TransferManagerShip(address opereator, address manager);
    
    function withdraw(address to,  uint amount) external;

    function transferManageShip(address manager) external;

    function signTransaction(uint transactionId, address receiver, uint256 amount) external;
}