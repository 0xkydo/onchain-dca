// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';
import '@uniswap/v3-periphery/contracts/libraries/TransferHelper.sol';

contract DCA is Ownable {

    // Public Variables
    address public constant USDC;
    address public constant WETH9;
    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint256 public amount;
    uint24 public constant poolFee = 500;
    
    // Private Variables
    address payable private _ledger;
    
    // Events
    event Swap(
        uint256 amountIn,
        uint256 amountOut
    );

    /*
    * @notice Initiate contract with the base asset and router for the swapping function.
    */
    constructor(
        uint256 _amount,
        address _router,
        address _USDC,
        address _WETH9,
        address payable cold
    ){
        swapRouter = ISwapRouter(_router);
        USDC = _USDC;
        WETH9 = _WETH9;
        amount = _amount;
        _ledger = cold;
    }

    function approve() public onlyOwner{
        // Approve the router to spend USDC.
        TransferHelper.safeApprove(USDC, address(swapRouter), _amount);
    }

    /*
    * @notice swap asset from USDC to WETH
    * @param amountMin The minimum amount of WETH output. Need to be calculated offchain
    */
    function swap(uint256 amountMin) public payable onlyOwner {

        // Transfer in base asset.
        baseAsset.transferFrom(_ledger, address(this), _amount);

        // Execute Swap
        // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: _ledger,
                deadline: block.timestamp,
                amountIn: _amount,
                amountOutMinimum: amountMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        emit Swap(_amount ,amountOut);

    }

    /*
    * @notice Remove all assets from Smart Contract in case funds being suck inside.
    */
    function unstuck() public payable {
        _ledger.transfer(address(this).balance);
        baseAsset.transfer(_ledger, baseAsset.balanceOf(address(this)));
    }
}