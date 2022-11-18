// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
pragma abicoder v2;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import '@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol';

contract DCA {

    //////////////////////
    // Public Variables //
    //////////////////////

    address public immutable baseTokenAddress;
    address public immutable targetTokenAddress;
    address payable public immutable recipient;
    uint256 public amount;
    uint24 public immutable poolFee;
    
    uint256 public maxEpoch;
    uint256 public currentEpoch;

    uint256 public immutable swapInterval;
    uint256 public swapTime;

    IERC20 public immutable BASE_TOKEN;
    IERC20 public immutable TARGET_TOKEN;

    ISwapRouter public immutable swapRouter = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
    

    ///////////////////////
    // Private Variables //
    ///////////////////////

    address payable private _fundingAddress;
    
    ////////////
    // Events //
    ////////////

    event Swap(
        address indexed baseTokenAddress,
        uint256 amountIn,
        address indexed targetTokenAddress,
        uint256 amountOut,
        address indexed executedBy
    );

    ///////////////
    // Modifiers //
    ///////////////

    modifier canSwap{
        require(block.timestamp >= swapTime);
        require(currentEpoch <= maxEpoch);
        _;
    }

    /*
    * @notice initialize contract with the base asset and router for the swapping function.
    * @param _amount: amount of token to sell.
    * @param _baseToken: address of token you are selling for the target token.
    * @param _targetToken: address of the token you are acquiring.
    * @param _interval: time interval between each DCA interval.
    * @param _startNow: 0 or 1 value. 0 -> start in the next interval. 1 -> dca starting now.
    * @param _recipient: address recieving the token from swaps.
    * @param _funder: the address paying for the swap.
    * @param _poolFee: the Uniswap pool you want to use for this pair.
    * @param _maxEpoch: maximum number of the swaps one can do.
    */
    constructor(
        uint256 _amount,
        address _baseToken,
        address _targetToken,
        uint256 _interval,
        uint8 _startNow,
        address payable _recipient,
        address payable _funder,
        uint24 _poolFee,
        uint256 _maxEpoch
    ){
        // initialize Token Addresses
        baseTokenAddress = _baseToken;
        targetTokenAddress = _targetToken;

        // initialize pool option
        poolFee = _poolFee;

        // initialize interval value
        swapInterval = _interval;
        
        // initialize next swap time.
        swapTime = block.timestamp + (1 - _startNow) * swapInterval;


        // initialize ERC20 tokens.
        BASE_TOKEN = IERC20(baseTokenAddress);
        TARGET_TOKEN = IERC20(targetTokenAddress);

        // initialize DCA amount for each epoch.
        amount = _amount;
        maxEpoch = _maxEpoch;
        currentEpoch = 0;
        
        // Set reciever of token.
        recipient = _recipient;
        _fundingAddress = _funder;

        // Approve DCA bot to interact with Uniswap router.
        BASE_TOKEN.approve(address(swapRouter), BASE_TOKEN.totalSupply());

    }

    /*
    * @notice swap asset from base to target
    * @param amountMin The minimum amount of target asset output. NOTE: Need to be calculated offchain.
    */
    function swap(uint256 amountMin) public payable canSwap returns (uint256 amountOut) {

        // Transfer in base asset.
        BASE_TOKEN.transferFrom(_fundingAddress, address(this), amount);

        // Execute Swap
        // https://docs.uniswap.org/protocol/guides/swaps/single-swaps
        ISwapRouter.ExactInputSingleParams memory params =
            ISwapRouter.ExactInputSingleParams({
                tokenIn: baseTokenAddress,
                tokenOut: targetTokenAddress,
                fee: poolFee,
                recipient: recipient,
                deadline: block.timestamp,
                amountIn: amount,
                amountOutMinimum: amountMin,
                sqrtPriceLimitX96: 0
            });

        amountOut = swapRouter.exactInputSingle(params);

        currentEpoch++;

        emit Swap(baseTokenAddress, amount, targetTokenAddress, amountOut, msg.sender);

    }

    /*
    * @notice Remove all ETH from Smart Contract in case funds being suck inside.
    */
    function unstuckETH() public payable {
        recipient.transfer(address(this).balance);
    }

    /*
    * @notice Remove all base asset from Smart Contract in case funds being suck inside.
    */
    function unstuckBase() public payable {
        BASE_TOKEN.transfer(recipient, BASE_TOKEN.balanceOf(address(this)));
    }

    /*
    * @notice Remove all target asset from Smart Contract in case funds being suck inside.
    */
    function unstuckTarget() public payable {
        TARGET_TOKEN.transfer(recipient, TARGET_TOKEN.balanceOf(address(this)));
    }
    
    

}