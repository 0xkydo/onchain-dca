# On-chain DCA Bot

## Goals
A noncustodial mechanism to DCA any ERC20 to another ERC20. 

## Requirements
1. The fund should always sit in a ledger ( $EOA_1$ ). 
2. $EOA_1$ signs one (maximum) transcation at the beginning and nothing in between.
3. $EOA_1$'s fund cannot be touched by other $EOA$.

## High level design

### Smart Contract
One smart contract ($SC$) that can execute only one function ``swap()``.
```
function swap() {
    require(block.timestap >= lastSwapTimestap + interval) // check if the interval between swaps have been reached.
    ERC20_1.transferFrom(from = Ledger, dst = SC, amt = n); //transfer ERC20_1 from ledger to SC
    Uniswap.swap(); // swap ERC20_1 to ERC20_2, and send to ledger.
}
```

### Automation
I will store the key pair for $EOA_2$ on the cloud server. I will use $EOA_2$ to call the ``swap()`` function in $SC$.

I will also deposit some ETH into $EOA_2$ for gas.

A js script would automate this with ethers.js.

## Cost Analysis
Cost can be split into two categories: LP fee and gas cost.

LP fee is easy to calculate. $300*0.05% = $0.15.

Gas cost consists of one ERC20 transferFrom, one Uniswap swap, and one ETH transfer.

| Action | Gas Cost |
| -------- | -------- |
| ERC20 transferFrom | 50,000 gas |
| Uniswap swap       | 150,000 gas     |
| ETH transfer       | 2,300 gas     |
| Total              | 202,300 gas     |

Currently, mainnet gas cost is around 10 gwei, if we execute this swap on an L2, which costs around 1/20 of mainnet. It would be 0.5 gwei per gas. If we assume ETH is $1200, total cost would be"

202,300 * 0.5 * 1200 / 1000000000 = **$0.12138**

Total onchain DCA cost = 0.15 + 0.121 = $0.271
% of amount transacted = 0.271 / 300 = 0.090333%

On Binance, a DCA bot would cost 0.2% in comparison.

## MEV Considerations

Most DCA amounts are small; therefore, it is not cost-effective do any kinds of MEV on top of these swaps.

If the swap amount is large, then one workaround is adding a modifier to the ``swap()`` function, so that only $EOA_2$, which sits in my cloud server, can call the swap function. I will relay the transaction through [Flashbot-RPC](https://docs.flashbots.net/flashbots-protect/rpc/quick-start/).

## Future Directions

### Generalized keepers
If we can build some economic incentive into ``swap()``, so that ``msg.sender`` can earn a piece of pie. This would replace the cloud server with individual [keepers](https://quantstamp.com/blog/mev-ethereums-dark-forest-and-keeperdao). This mechanism is similar to liquidators and other automated workers that currently lives on Ethereum. See examples: [Sommelier](https://www.sommelier.finance/), [Gelato](https://www.gelato.network/), [Gamma](https://www.gamma.xyz/).