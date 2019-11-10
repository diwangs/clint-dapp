# clint-dapp
A crowdsourced bank credit system based on Ethereum

## Architecture
The dApp is divided into 3 contracts:
* `TrstToken` is the contract that handles token transaction
* `Vault` is the contract that handles lending logic
* `Staking` is the contract that handles voting logic

## Public interface
* TrstToken
  * State getters
    * `balance(address)`
    * `price()`
    * `totalSupply()`
  * `redeem(amount)`
* Vault
  * State getters
    * `loanStatus(address)`
    * `proposedLoan(address)`
    * `term(address)`
    * `lentTimestamp(address)`
    * `interestRateNum()`, `interestRateDenom()`
    * `latenessMultiplierNum()`, `latenessMultiplierDenom()`
  * `proposeLoan(amount, dueDuration)`
  * `cancelProposal()`
  * `returnLoan()`
* Staking
  * State getters
    * `upperThreshold()`
    * `lowerThreshold()`
    * `rewardRateNum()`, `rewardRateDenom()`
    * `punishmentRate()`, `punishmentRateDenom()`
    * `stake(candidate, staker)`
    * `totalStake(candidate)`
    * `stakers(candidate)`
  * `setStake(candidate, amount)`
  * `cancelStake(candidate)`

## Dev Setup
1. `npm install` or `yarn install`
2. Install metamask browser plugin (from your browser web store), this is used to enable your browser to communicate with Ethereum

## Testing
`yarn exec truffle test`

## Deployment
TBA