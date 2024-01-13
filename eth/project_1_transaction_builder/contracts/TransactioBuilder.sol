// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./UniswapInterface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UniswapInteraction {
    using SafeMath for uint;

    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;
    address private constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    address private constant UNISWAP_FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;

    event AddedLiquidity(
        string message,
        uint amountTokenA,
        uint amountTokenB,
        uint liquidity
    );


    function _performSwap(
        address _tokenFrom,
        address _tokenTo,
        uint _amountFrom
    ) internal returns (uint[] memory) {
        IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountFrom);
        IERC20(_tokenFrom).approve(UNISWAP_ROUTER, _amountFrom);

        address[] memory path;

        if (_tokenFrom == WETH || _tokenTo == WETH) {
            path = new address[](2);

            path[0] = _tokenFrom;
            path[1] = _tokenTo;
        } else {
            path = new address[](3);

            path[0] = _tokenFrom;
            path[1] = WETH;
            path[2] = _tokenTo;
        }

        return IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
                   _amountFrom,
                   0,
                   path,
                   msg.sender,
                   block.timestamp
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB
    ) internal {
        uint balA = IERC20(_tokenA).balanceOf(msg.sender);
        uint balB = IERC20(_tokenB).balanceOf(msg.sender);

        require (balA >= _amountA);
        require (balB >= _amountB);

        IERC20(_tokenA).transferFrom(msg.sender, address(this), _amountA);
        IERC20(_tokenB).transferFrom(msg.sender, address(this), _amountB);

        IERC20(_tokenA).approve(UNISWAP_ROUTER, _amountA);
        IERC20(_tokenB).approve(UNISWAP_ROUTER, _amountB);


        (
            uint amountTokenA,
            uint amountTokenB,
            uint liquidity
        ) = IUniswapV2Router(UNISWAP_ROUTER).addLiquidity(
                _tokenA,
                _tokenB,
                _amountA,
                _amountB,
                0,
                0,
                address(this),
                block.timestamp
        );

        emit AddedLiquidity(
            "liquidity added successfully",
            amountTokenA,
            amountTokenB,
            liquidity
        );
    }

    function AddLiquidity(
        address tokenFrom,
        uint amountFrom,
        address tokenA,
        address tokenB
    ) external {
        uint userTokenBalance = IERC20(tokenFrom).balanceOf(msg.sender);
        require (userTokenBalance >= amountFrom);

        uint halfAmount = amountFrom.div(2);

        uint[] memory swappedA = _performSwap(
                                    tokenFrom,
                                    tokenA,
                                    halfAmount
                                );

        if (swappedA[0] != halfAmount) {
            return;
        }

        uint[] memory swappedB = _performSwap(
                                    tokenFrom,
                                    tokenB,
                                    halfAmount
                                );

        if (swappedB[0] != halfAmount) {
            return;
        }

        _addLiquidity(tokenA, tokenB, swappedA[1], swappedB[1]);
    }
}
