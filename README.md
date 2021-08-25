# UpsideDai [![CircleCI](https://circleci.com/gh/Daichotomy/UpSideDai/tree/master.svg?style=svg)](https://circleci.com/gh/Daichotomy/UpSideDai/tree/master) [![Coverage Status](https://coveralls.io/repos/github/Daichotomy/UpSideDai/badge.svg?branch=master)](https://coveralls.io/github/Daichotomy/UpSideDai?branch=master)

![](src/assets/Logo.png)

## Resources

- [Live Platform](https://upsidedai.com)  
- [Pitch deck](https://docs.google.com/presentation/d/1qZtUZ2vuH_k8AtWUEa444_UhoD8DlzgenaHmmxuohMU)  
- [Figma mockups](https://www.figma.com/file/561C0EC33s556EpVKYBzG2/Eth-Denver?node-id=8%3A0)
- [Youtube demo](https://youtu.be/ZfAq1ypdMdo)

## ETHDenver 2020 Winners

 - [Open Track Winners](https://alchemy-xdai.daostack.io/dao/0xe248a76a4a84667c859eb51b9af6dea29e52f139/crx/proposal/0xc2584683cbf5f10af39fb2b79b62ff967608a9e179241e0fce9c8f6dbd6a579a)
 - [DeFi Rate shoutout (](https://defirate.com/ethdenver-defi/)
 - [TheBlock write up (highlights)](https://www.theblockcrypto.com/post/56159/ethdenver-defi-project-highlights)
 - [DaoStack tweet](https://twitter.com/daostack/status/1229840533666893826)

## Table of Contents

- [What is UpSideDai](#what-is-upsidedai)
- [Team](#team)
- [Financial engineering](#financial-engineering)
  - [On-chain Price of Dai in USD](#on-chain-price-of-dai-in-usd)
  - [Calculating The Settlement Price Of The CDF](#calculating-the-settlement-price-of-the-cdf)
  - [Incentives For Market Makers](#incentives-for-market-makers)
  - [Transaction Flow](#transaction-flow)
- [Local Development Setup](#local-development-setup)
  - [Testing](#testing)
  - [Code Linting](#code-linting)
- [Networks](#networks)
  - [Mainnet](#mainnet)
- [Technical Description](#technical-description)

---

## What is UpSideDai ??

UpsideDai is a **highly leveraged** contract for difference (CFD) built on Dai, Uniswap and Maker. This mechanism enables traders and speculators to bet on and hedge against price fluctuations of Dai by buying leveraged long or short positions. The CFD construction enables high leverage (20x) while remaining capital efficient and not requiring high margin requirements (100% collateralization). Positions are priced against the market observable Dai/Usd price by using a combination of the Maker oracle and Uniswap.

UpsideDai's CFD uses two tokens within the platform: UpDai and DownDai which represent long and short positions against the price of Dai. A market maker deposits 2 Dai into the platform to create 1 upDai and 1 downDai. When Dai is trading at par with the dollar (1Dai = 1Usd) then

```
 1 upDai = 1 downDai = 1 Dai = 1 Usd
```

As the price of Dai fluctuates around 1 Usd value flows between the upDai and downDai tokens. The sum of the upDai and downDai token is always equal, netting price action between the tokens This means that irrespective of the price of Dai a pair of upDai and downDai tokens yields 2 Dai in underlying. **For example if the price of Dai is trading at 1.02 Usd then the long token is worth 1.4 Dai and the downDai is worth 0.6 Dai**.

The price that Dai can fluctuate around the peg is bounded by the leverage used by the CFD. UpsideDai's 20x leverage places a bound on the price of Dai between 1.05 and 0.95 Usd per Dai. This bound is reasonable as Dai has not broken this bound in over a year. However if Dai was to hit one of the bounds, say it's trading at 1.05, then the long token is worth 2 Dai and the short Dai is worth 0 Dai. If a wider bound is wanted then either less leverage should be used or more collateralization is required.

## Team

🇮🇪 Alex Scott - Smart contracts and integrations

🇨🇴 Diego Mazo - Product and front end design

🇿🇦 Chris Maree - Financial engineering and front end

🇹🇳 Haythem Sellami - Smart contracts and front end

## Financial engineering

A contract for difference is a contract between two parties stipulating that the buyer will pay to the seller the difference between the current value of an asset and its value at contract time. UpsideDai's implementation pays out the difference between the price of Dai and 1 USD with **20x leverage**. A CFD is a synthetic contract, representing synthetic price exposure to an underlying fictitious asset. As such it requires a maturity at which tokens can be redeemed for underlying. This ensures that the price of the token in the secondary market has a low tracking error to the underlying price feed.

### On-chain Price of Dai in USD

At settlement the price of Dai in Usd is needed to define how much each upDai and downDai tokens are redeemable for. This _could_ be build using an oracle but we chose to rather find a trustless on-chain representation of the price of Dai. This is found by getting the Eth/Usd price from the Maker Medianzer and the Eth/Dai price from Uniswap. The uniswap price divided by the Maker medianizer price yields the current on chain price of Dai without needing an oracle or external price feed. Numerically this can be defined as follows:

![](./Diagrams/PriceOfDai.gif)

### Calculating The Settlement Price Of The CDF

Contracts in UpsideDai run for a one month maturity. At settlement token holders can redeem their upDai and downDai for a representative amount of underlying Dai. The amount of Dai that they can redeem(`payout`) is a function of how many `upDai` or `downDai` they hold, the settlement price of Dai in Usd(`p`), leverage(`L`) and market fees(`f`). This is expressed as follows:

![](./Diagrams/payout.gif)

If a token holder only has upDai or downDai then they yield the commensurate amount from that position. If a market maker holds equal amounts of both tokens they yield their full underlying + fees and interest (more on this in the next section).

### Incentives For Market Makers

A key element of UpsideDai is an incentive mechanism to encourage liquidity provision from market makers. This is done in a number of ways:

1. All underlying is invested into the DSR using Chai to yield interest on deposits over the life span of the contract. This is redeemable by the market makers when they redeem at maturity of the contract
2. Uniswap pools generate 0.3% fees on all trades, which is given to market makers.
3. Redemption from the CDF charges a fee `f` of 0.3% which also goes to the market makers.

These three sources of revenue makes being a liquidity provider for UpsideDai more profitable than investing in the money market or DSR while having minimum risk.

### Transaction Flow

- At any time a new Contract For Difference get created, a new UPDAI (Long token) and DOWNDAI (short token) tokens get created with a Uniswap exchange for each one. The fee, leverage and the settlement date are configurable parameters at the deployment time.

...

## Local Development Setup

For local development it is recommended to use [ganache](http://truffleframework.com/ganache/) to run a local development chain. Using the ganache simulator no full Ethereum node is required.

As a pre-requisite, you need:

- Node.js
- npm

Clone the project and install all dependencies:

    git clone git@github.com:Daichotomy/UpSideDai.git
    cd UpSideDai/

    # install project dependencies
    $ npm i

Compile the solidity contracts:

    $ npm run compile

In a new terminal, launch an Ethereum RPC client, we use the default ganache-cli command to configure and run a local development ganache:

    $ npm run ganache

Switch back to your other terminal and deploy the contracts:

    $ npm run migrate:development

Make sure to setup the deployments parameters in `./migrations/deployment-config.json` file

### Testing

Run tests with:

    $ npm run test

### Code Linting

Linting is setup for `JavaScript` with [ESLint](https://eslint.org) & Solidity with [Solhint](https://protofire.github.io/solhint/) 

    # lint solidity contracts
    $ npm run lint:contracts

    # lint tests
    $ npm run lint:tests

Code style is enforced through the CI test process, builds will fail if there're any linting errors.

## Networks

### Mainnet

The contract addresses deployed on `Mainnet` Mainnet:

| Contract                  | Address                                                                                                               |
| ------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| UpSideDai                 | [0xaE2F528965280278A4653dC0092779d3016fcDA6](https://etherscan.io/address/0xaE2F528965280278A4653dC0092779d3016fcDA6) |
| CFD                       | [0xdb3ff384bAFf85A734DEf4888576Fa54010050D4](https://etherscan.io/address/0xdb3ff384bAFf85A734DEf4888576Fa54010050D4) |
| UPDAI                     | [0x78FF871EcDbC2DAb4212772192b48cAE1ec74b8E](https://etherscan.io/address/0x78FF871EcDbC2DAb4212772192b48cAE1ec74b8E) |
| DOWNDAI                   | [0xBC95FD0847E5982052f246402c9ca07D6B147139](https://etherscan.io/address/0xBC95FD0847E5982052f246402c9ca07D6B147139) |
| UPDAI Uniswap Exchange    | [0x1F4488E2569b78C5Df38c0EEfdbc25a205931305](https://etherscan.io/address/0x1F4488E2569b78C5Df38c0EEfdbc25a205931305) |
| DOWNDAI Uniswap Exchange  | [0x70e76de7A90A77F2bdaa3a6fE7950C247591C5BA](https://etherscan.io/address/0x70e76de7A90A77F2bdaa3a6fE7950C247591C5BA) |
| Uniswap Factory           | [0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95](https://etherscan.io/address/0xc0a47dFe034B400B47bDaD5FecDa2621de6c4d95) |
| MakerDAO Medianizer       | [0xE3774Af455602C5a0EACC1b0f93e3cE0f65236ce](https://etherscan.io/address/0xE3774Af455602C5a0EACC1b0f93e3cE0f65236ce) |

## Technical Description

![](Diagrams/UpSideDai.png)

You can find more in our [smart contracts documentation](docs/CFD.md)
