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
    * `stakable()` ghetto method
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
2. Start the Ethereum dev node and leave it running. Either,
   * If you don't have Ganache installed, open a new terminal and `yarn start`
   * If you have it installed, start Ganache and add `truffle-config.js` to its project setting
3. `yarn build` or `yarn ganache-build`, depending if you use Ganache or not

## Testing
`yarn test`

## Deployment
TBA