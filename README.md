# Sock Swap

Welcome to this brief overview of `SockSwap`. Hopefully, this repository can serve as a blueprint for more fun real world asset experiments :)

## Scope and Objectives

`SockSwap` allows you, [the hacker](https://stallman.org/articles/on-hacking.html), to setup a 'swag shop' for classifying and/or bartering physical goods. The initial design was conceived at an ETH Global hackathon and as such works in a limited set of real world circumstances where most people can be coerced into playing by the rules.

## References

- [ERC-6909: Minimal Multi-Token Interface](https://eips.ethereum.org/EIPS/eip-6909)
- [How to use Reality.eth + Kleros as an oracle](https://docs.kleros.io/integrations/types-of-integrations/1.-dispute-resolution-integration-plan/channel-partners/how-to-use-reality.eth-+-kleros-as-an-oracle)
- https://ethglobal.com/showcase/sockswap-2z8r8

## Technical Requirements

- https://github.com/foundry-rs/foundry
- https://github.com/Vectorized/solady

```
forge install vectorized/solady --no-commit --no-git
forge install foundry-rs/forge-std --no-commit --no-git // :^)
```

`SockSwap` is an MIT licensed **testnet-only** protocol. Check [the reality.eth monorepo](https://github.com/RealityETH/reality-eth-monorepo/tree/main/packages/contracts/chains/deployments) to see if you will need to deploy your own oracle. The `timeout` can be adjusted as necessary but ideally you pick a live chain that doesn't go down during the course of the hackathon.

---

Functionally, there are 3 actions that users of `SockSwap` need to be able to perform

1. Classification - assigning unique pairs of socks to token IDs
2. Minting - creating tokens when socks are deposited
3. Redemption - burning tokens in exchange for socks

Sanitation & the safety of all participants are tantamount so ensure only unworn & complete pairs of socks are accepted.

## Materials and Components

- You will need a box to hold the socks, it should be at least as big as a foot
- The more the merrier; if you are a team of one you cannot leave the box unattended
  - security personnel may be assigned the `AUDITOOR` role if you trust their ability to count accurately
- In order for the questions to never lead to dispute arbitration you may want a fat stack of testnet tokens (or some hired muscle)

## Design and Architecture

the `SockSwap` contract is what users interact with. Aside from doing the usual semi-fungible things, it has the public methods to perform the 3 above actions in however many steps it may take (depends on if you're in real life) plus one function for the `Owner` to set a `RuleBook`

the `RuleBook` contracts set the rules for what's required for each of the steps. `CarteBlanche` is for mock socks; as a sanity check it enforces that tokens are pre-registered but all the usual accounting is taken care of by solady's ERC-6909 implementation. `RealRulebook` requires an oracle to pose questions to because it's real life.. And since you need time to communicate the state of the world back on chain - receiving answers requires a second transaction.

### Tricky Bits

We require a commit reveal scheme for the token ID in order to avoid front-running (using someone else's photo as your own).

Requesting/performing an audit is a permissioned action to avoid deadlock from griefing.

## Testing and Acceptance Criteria

Apologies in advance, the tests are a scratchpad and only cover the happy path
