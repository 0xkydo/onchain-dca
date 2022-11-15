// contracts/MyContract.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract DCA is Ownable {

    // Public Variables
    address public immutable USDC;
    address public immutable WETH9;
    address payable public immutable recipient;

    uint256 public immutable swapInterval;
    uint256 public swapTime;

    IERC20 public immutable USDC_TOKEN;
    IERC20 public immutable WETH9_TOKEN;

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    uint256 public amount;
    uint24 public constant poolFee = 500;
    
    
    // Events
    event Construction(
        uint256 amount,
        address recipient
    );

    event Swap(
        uint256 amountIn,
        uint256 amountOut
    );

    // Modifiers
    modifier canSwap{
        require(block.timestamp >= swapTime);
        _;
    }

    /*
    * @notice Initiate contract with the base asset and router for the swapping function.
    * @param _amount: amount of token to sell. NOTE: Uses 18 decimal as base.
    * @param
    * @param
    * @param _interval: time interval between each DCA interval. Value input is in days.
    * @param _startNow: 0 or 1 value. 0 -> start in the next interval. 1 -> dca starting now.
    * @param
    */
    constructor(
        uint256 _amount,
        address _USDC,
        address _WETH9,
        uint256 _interval,
        uint8 _startNow,
        address payable _recipient
    ){
        // Initiate Token Addresses
        USDC = _USDC;
        WETH9 = _WETH9;

        // Initiate interval value
        swapInterval = _interval * 60 * 60 * 24;
        
        // Initiate next swap time.
        swapTime = block.timestamp + (1 - _startNow) * swapInterval;


        // Initate ERC20 tokens.
        USDC_TOKEN = IERC20(USDC);
        WETH9_TOKEN = IERC20(WETH9);

        // Initate DCA amount for each epoch.
        amount = _amount * 10 ** 18; // NOTE: adds 18 0's. Might need to change later.
        
        // Set reciever of token.
        recipient = _recipient;

        // Approve DCA bot to interact with Uniswap router.
        USDC_TOKEN.approve(address(swapRouter), USDC_TOKEN.totalSupply());

        emit Construction(amount, recipient);
    }

    /*
    * @notice swap asset from USDC to WETH
    * @param amountMin The minimum amount of WETH output. NOTE: Need to be calculated offchain.
    */
    function swap(uint256 amountMin) public payable onlyOwner canSwap returns (uint256 amountOut) {

        // Transfer in base asset.
        USDC_TOKEN.transferFrom(recipient, address(this), amount);

        // Execute Swap
        // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: USDC,
                tokenOut: WETH9,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: amountMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        emit Swap(amount ,amountOut);

    }

    /*
    * @notice Remove all assets from Smart Contract in case funds being suck inside.
    */
    function unstuck() public payable {
        recipient.transfer(address(this).balance);
        USDC_TOKEN.transfer(recipient, USDC_TOKEN.balanceOf(address(this)));
    }
}