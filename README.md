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
  * `proposeLoan(amount, term)`
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
2. `yarn start`
3. Open a new terminal, `yarn build`, close the terminal

## Testing
`yarn exec truffle test`

## Deployment
TBA