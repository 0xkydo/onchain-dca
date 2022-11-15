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
    IERC20 public baseAsset;
    uint256 public amount;
    address public router;

    // Private Variables
    address payable private _ledger;
    
    // Events
    event Swap(
        uint40 amountIn,
        uint40 amountOut
    );

    /*
    * @notice Initiate contract with the base asset and router for the swapping function.
    */
    constructor(
        uint256 _amount,
        address _router,
        address _baseAsset,
        address payable ledger
    ){
        router = _router;
        baseAsset = IERC20(_baseAsset);
        amount = _amount;
        _ledger = ledger;
    }

    /*
    * @notice swap asset from
    */
    function swap() public payable onlyOwner {

        
    }

    /*
    * @notice Remove all assets from Smart Contract in case funds being suck inside.
    */
    function unstuck() public payable {
        _ledger.transfer(address(this).balance);
        baseAsset.transfer(_ledger, baseAsset.balanceOf(address(this)));
    }
}