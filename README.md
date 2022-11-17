# On-chain DCA Bot

## Goals
A noncustodial mechanism to swap 300 USDC to ETH every fixed time period ($k$) on chain. 

## Requirements
1. The fund should always sit in a ledger ($EOA_1$). 
2. $EOA_1$ signs one transcation at the beginning and nothing in between.
3. $EOA_1$'s fund cannot be touched by other $EOA$.

## High level design

### Smart Contract
One smart contract ($SC$) that can execute only one function ``swap()``.
```
function swap() onlyOwner() {
    USDC.transferFrom(from = Ledger, dst = SC, amt = 200); //transfer USDC from ledger to SC
    Uniswap.swap(); // swap USDC to ETH
    Ledger.transfer(getBalance()); // transfer all ETH in SC back to ledger.
}
```
Owner of the SC should be set to an EOA different from the ledger. I will call this EOA, $EOA_2$.

### Automation
I will store the key pair for $EOA_2$ on the cloud server. I will use $EOA_2$ to call the ``swap()`` function in $SC$.

I will also deposit some ETH into $EOA_2$ for gas.

A js script would automate this with web3.js and Uniswap's SDK.

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
