# clint-dapp
A crowdsourced bank credit system based on Ethereum

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
  * TBA

## Dev Setup
1. `npm install` or `yarn install`
2. Install metamask browser plugin (from your browser web store), this is used to enable your browser to communicate with Ethereum

## Testing
`yarn exec truffle test`

## Deployment
TBA