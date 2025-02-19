# Jackpot

A Uniswap v4 hook that allows any pool to participate in a 6/49 Lotto lottery.

## Core Logic

- LP can stake their liquidity and fees for Lotto winnings
- Swapper can use token swaps to participate in 6/49 Lotto

## Hooks Features

- [ ] `Dynamic Fee Hook` - pays for Lotto balls, and adds liquidity to Jackpot pool
- [ ] `beforeInitialize()` - checks if pool supports dynamic fees
- [ ] `beforeAddLiquidity()` - check if LP wants to play house in Lottery
- [ ] `beforeRemoveLiquidity()` - checks for LP Lottery participation
- [ ] `beforeSwap()` - check is swapper is creating a Lottery Draw
- [ ] `afterSwap()` - completes swap and lottery draw logic

## Lotto Draw NFT

NFT draws

![Lotto Draw](./docs/Ticket.png)

## 'Good luck!'
