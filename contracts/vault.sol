// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./interface/IVault.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";

contract Vault is IVault,Context{
    using SafeERC20 for IERC20;

    mapping (address => uint256) private managers;

    address public constant AFK = 0x9D88519e9a847044E443E5B62639317652fd001C;
    
    uint256 constant MIN_SIGNATURES = 3;
    uint256 constant validBlock = 28800;

    uint256 transactionIdx;
    bytes32 transactionHash;
    Transaction public transaction;
    
    struct Transaction {
        address receiver;
        uint256 amount;
        uint256 signatureCount;
        uint256 transactionIdx;
        uint256 beginBlock;
        mapping (address=>uint256) signatures;
    }
    
    constructor(address[5] memory managers_) {
        for(uint256 i = 0; i < 5; i++) {
            managers[managers_[i]] = 1;
        }
    }
    
    function transferManageShip(address manager) external override onlyManager{
        managers[_msgSender()] = 0;
        managers[manager] = 1;
    }
    
    function withdraw(address to,  uint amount) external override onlyManager{
        require(IERC20(AFK).balanceOf(address(this)) >= amount);
        transactionIdx++;

        delete transaction;

        bytes32 tempTransactionHash = keccak256(abi.encodePacked(transactionIdx, to, amount));
        transactionHash = tempTransactionHash;
        transaction.amount = amount;
        transaction.signatureCount = 1;
        transaction.receiver = to;
        transaction.transactionIdx = transactionIdx;
        transaction.beginBlock = block.number;
        transaction.signatures[_msgSender()] = 1;
        emit TransactionCreated(_msgSender(), to, amount, transactionIdx);
    }
    
    function signTransaction(uint transactionId, address receiver, uint256 amount) external override onlyManager{
        bytes32 tempTransactionHash = keccak256(abi.encodePacked(transactionId, receiver, amount));
        require(tempTransactionHash == transactionHash,"transaction is invalid");
        require(block.number - transaction.beginBlock <= validBlock, "transaction is invalid");
        require(transaction.signatures[_msgSender()] != 1, "already sign");
        transaction.transactionIdx;
        transaction.signatureCount++;
        transaction.signatures[_msgSender()] = 1;
        if (transaction.signatureCount >= MIN_SIGNATURES) {
            require(IERC20(AFK).balanceOf(address(this)) >= amount);
            IERC20(AFK).safeTransfer(receiver, amount);
            emit TransferFunds(receiver, amount);
            delete transaction;   
        }
        
    }

    modifier onlyManager() {
        require(managers[_msgSender()] == 1, "only Manager call it");
        _;
    }   
}