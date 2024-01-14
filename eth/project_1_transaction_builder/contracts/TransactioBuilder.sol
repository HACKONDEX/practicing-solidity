// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "./UniswapInterface.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract UniswapInteraction {
    using SafeMath for uint;

    address private constant UNISWAP_ROUTER = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    event AddedLiquidity(
        string message,
        uint amountTokenA,
        uint amountTokenB,
        uint liquidity
    );

    event NotEnoughSwapped(
        address token,
        uint expectedToSwap,
        uint swapped
    );

    function testBalanceOfToken(address _tokenFrom) public view returns(uint) {
        return IERC20(_tokenFrom).balanceOf(msg.sender);
    }

    function testCompareBalance(address _tokenFrom, uint _amount) public view returns(bool) {
        uint bal = IERC20(_tokenFrom).balanceOf(msg.sender);
        if (bal > _amount) {
            return true;
        }
        return false;
    }

    function testCheckAllowance(address _token) public view returns(uint) {
        return IERC20(_token).allowance(msg.sender, address(this));
    }

    function donateToContractFromUser(address _tokenFrom, uint _amountFrom) public returns(uint) {
        uint bal = IERC20(_tokenFrom).balanceOf(msg.sender);
        if (bal > _amountFrom) {
            uint doubleAmount = _amountFrom.mul(2);
            IERC20(_tokenFrom).approve(UNISWAP_ROUTER, doubleAmount);

            bool res = IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountFrom);
            if (res) {
                return 1;
            }
            return 0;
        }
        return 2;
    }

    function PerformSwap (
        address _tokenFrom,
        address _tokenTo,
        uint _amountFrom
    ) public {
        IERC20(_tokenFrom).transferFrom(msg.sender, address(this), _amountFrom);
        IERC20(_tokenFrom).approve(UNISWAP_ROUTER, _amountFrom);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenFrom;
        path[1] = _tokenTo;

        IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
                   _amountFrom,
                   1,
                   path,
                   msg.sender,
                   block.timestamp
        );
    }

    function _getTokenFromToken(
        address _tokenFrom,
        address _tokenTo,
        uint _amountFrom
    ) internal returns(uint) {
        uint[] memory swapResult = _performSwapForContract(
                                    _tokenFrom,
                                    _tokenTo,
                                    _amountFrom
                                );

        if (swapResult[0] != _amountFrom) {
            emit NotEnoughSwapped(_tokenTo, _amountFrom, swapResult[0]);
        }

        return swapResult[1];
    }

    function _performSwapForContract(
        address _tokenFrom,
        address _tokenTo,
        uint _amountFrom
    ) internal returns (uint[] memory) {
        // change allowance for this contract and uniswap router
        IERC20(_tokenFrom).approve(UNISWAP_ROUTER, _amountFrom);

        address[] memory path;
        path = new address[](2);
        path[0] = _tokenFrom;
        path[1] = _tokenTo;

        // swap from -> to, save in contract
        return IUniswapV2Router(UNISWAP_ROUTER).swapExactTokensForTokens(
                   _amountFrom,
                   1,
                   path,
                   address(this),
                   block.timestamp
        );
    }

    function _addLiquidity(
        address _tokenA,
        address _tokenB,
        uint _amountA,
        uint _amountB,
        address _recipient
    ) internal {
        // need to update allowance before changing liquidity
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
                1, // min amount
                1, // min amount
                _recipient,
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
        // transfer all from user to contract
        // should be called after approve(addres(this)) on frontend
        IERC20(tokenFrom).transferFrom(msg.sender,
                                       address(this),
                                       amountFrom);

        uint halfAmount = amountFrom.div(2);

        // exchange tokens in contract
        uint amountTokenA = _getTokenFromToken(tokenFrom, tokenA, halfAmount);
        uint amountTokenB = _getTokenFromToken(tokenFrom, tokenB, halfAmount);

        _addLiquidity(tokenA,
                      tokenB,
                      amountTokenA,
                      amountTokenB,
                      /* recipient */
                      msg.sender);
    }
}
/*

Useful addresses

18 DC, LINK - 0x326C977E6efc84E512bB9C30f76E30c160eD06FB
18 DC, WETH - 0xB4FBF271143F4FBf7B91A5ded31805e42b2208d6
6  DC, USDC - 0x2f3A40A3db8a7e3D09B0adfEfbCe4f6F81927557

*/