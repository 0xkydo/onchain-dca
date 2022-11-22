// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./DCA.sol";

contract DCAFactory{
    DCA[] public DCABots;

    address[] public DCABotRecipient;

    event DCACreated(
        address indexed funder,
        address indexed recipient,
        address indexed bot,
        address baseToken,
        address targetToken,
        uint256 amount,
        uint256 interval,
        uint256 maxEpoch
    );

    /*
    * @notice documentation copied from DCA.sol's constructor. Create function creates a new instance of DCA and stores address.
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
    function createDCA (
        uint256 _amount,
        address _baseToken,
        address _targetToken,
        uint256 _interval,
        uint8 _startNow,
        address payable _recipient,
        address payable _funder,
        uint24 _poolFee,
        uint256 _maxEpoch
    ) public {
        
        // Deploy new DCA Bot.
        DCA newDCA = new DCA(
            _amount,
            _baseToken,
            _targetToken,
            _interval,
            _startNow,
            _recipient,
            _funder,
            _poolFee,
            _maxEpoch
        );
        
        // Store new DCA Bot address and recipient for the bot.
        DCABots.push(newDCA);
        DCABotRecipient.push(_recipient);

        emit DCACreated(
            _funder,
            _recipient,
            address(newDCA),
            _baseToken,
            _targetToken,
            _amount,
            _interval,
            _maxEpoch
        );

    }

    // Query length of total DCA bot length. For front end purposes.
    function totalDCALength() external view returns (uint256) {
        return DCABots.length;
    }


}
