const BigNumber = require('bignumber.js'); // avoid overflow
// TODO: change all number to BigNumber?

const TrstToken = artifacts.require("TrstToken");
const Vault = artifacts.require("Vault");

const PREFIX = "Returned error: VM Exception while processing transaction: "
const AUTH_ERR = "You're not authorized"
const DOUBLE_LEND_ERR = "You already have an active loan"
const NO_LEND_ERR = "You don't have an active loan"

async function getGasCost(txinfo) {
    const tx = await web3.eth.getTransaction(txinfo.tx);
    const gasPrice = new BigNumber(tx.gasPrice)
    const gasUsed = new BigNumber(txinfo.receipt.gasUsed)
    return gasPrice.times(gasUsed);
  }

contract('Vault', (accounts) => {
    const root = accounts[0]
    const rando = accounts[1]

    describe("Administrative Methods", () => {
        describe("deposit (Fallback Function)", () => {
            it('should allow deposit', async () => {
                await Vault.deployed();
                const amount = web3.utils.toWei("1", "ether")
            
                const balanceBefore = await web3.eth.getBalance(Vault.address)
                await web3.eth.sendTransaction({
                    from: root,
                    to: Vault.address,
                    value: amount
                })
                const balanceAfter = await web3.eth.getBalance(Vault.address)
            
                assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), amount, "Transaction unsuccesful")
            })
        })

        describe("withdraw", () => {
            it("should allow root to withdraw properly", async () => {
                const vaultContract = await Vault.deployed();
                const amount = web3.utils.toWei("0.5", "ether")
            
                const balanceBefore = new BigNumber(await web3.eth.getBalance(root))
                const txinfo = await vaultContract.withdraw(amount, {from: root});
                const gasCost = await getGasCost(txinfo)
                const balanceAfter = new BigNumber(await web3.eth.getBalance(root))

                assert.equal(balanceAfter.minus(balanceBefore).plus(gasCost).valueOf(), amount, "Transaction unsucessful");
            })

            it("shouldn\'t allow rando to withdraw", async () => {
                const vaultContract = await Vault.deployed();
                const amount = web3.utils.toWei("0.5", "ether")
            
                try {
                    await vaultContract.withdraw(amount, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setInterestRateNum", () => {
            it("should allow interestRateNum to be set by root", async () => {
                const vaultContract = await Vault.deployed();
            
                await vaultContract.setInterestRateNum(2, {from: root})
                const interestRateNum = await vaultContract.interestRateNum();
        
                assert.equal(interestRateNum.valueOf(), 2, "interestRateNum doesn't change");
            })
      
            it("shouldn\'t allow interestRateNum to be set by rando", async () => {
                const vaultContract = await Vault.deployed();
            
                try {
                    await vaultContract.setInterestRateNum(1, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setInterestRateDenom", () => {
            it("should allow interestRateDenom to be set by root", async () => {
                const vaultContract = await Vault.deployed();
            
                await vaultContract.setInterestRateDenom(10001, {from: root})
                const interestRateDenom = await vaultContract.interestRateDenom();
        
                assert.equal(interestRateDenom.valueOf(), 10001, "interestRateDenom doesn't change");
            })
      
            it("shouldn\'t allow interestRateDenom to be set by rando", async () => {
                const vaultContract = await Vault.deployed();
            
                try {
                    await vaultContract.setInterestRateDenom(1000000, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setLatenessMultiplierNum", () => {
            it("should allow latenessMultiplierNum to be set by root", async () => {
                const vaultContract = await Vault.deployed();
            
                await vaultContract.setLatenessMultiplierNum(2, {from: root})
                const latenessMultiplierNum = await vaultContract.interestRateNum();
        
                assert.equal(latenessMultiplierNum.valueOf(), 2, "interestRateNum doesn't change");
            })
      
            it("shouldn\'t allow latenessMultiplierNum to be set by rando", async () => {
                const vaultContract = await Vault.deployed();
            
                try {
                    await vaultContract.setLatenessMultiplierNum(1, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setLatenessMultiplierDenom", () => {
            it("should allow latenessMultiplierDenom to be set by root", async () => {
                const vaultContract = await Vault.deployed();
            
                await vaultContract.setLatenessMultiplierDenom(1209601, {from: root})
                const latenessMultiplierDenom = await vaultContract.latenessMultiplierDenom();
        
                assert.equal(latenessMultiplierDenom.valueOf(), 1209601, "latenessMultiplierDenom doesn't change");
            })
      
            it("shouldn\'t allow latenessMultiplierDenom to be set by rando", async () => {
                const vaultContract = await Vault.deployed();
            
                try {
                    await vaultContract.setLatenessMultiplierDenom(10000000, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })
    })

    describe("Operation Methods", () => {
        describe("proposeLoan", () => {
            it('should allow rando to propose properly', async () => {
                const vaultContract = await Vault.deployed();
                const amount = new BigNumber(web3.utils.toWei("1", "ether"))
                
                await vaultContract.proposeLoan(amount, "1209600", {from: rando})
                
                const loanStatus = await vaultContract.loanStatus(rando);
                assert.equal(loanStatus.valueOf(), 1, "Transfer unsucessful")
            });
        
            it('shouldn\'t allow rando to propose twice', async () => {
                const vaultContract = await Vault.deployed();
                
                try {
                    await vaultContract.proposeLoan(1, "1209600", {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + DOUBLE_LEND_ERR))
                }
            })
        })

        describe("cancelProposal", () => {
            it('should allow rando to cancel proposal properly', async () => {
                const vaultContract = await Vault.deployed();
                
                await vaultContract.cancelProposal({from: rando})
                
                const loanStatus = await vaultContract.loanStatus(rando);
                assert.equal(loanStatus.valueOf(), 0, "Cancelation unsucessful")
            });
        
            it('shouldn\'t allow rando to cancel twice', async () => {
                const vaultContract = await Vault.deployed();
                
                try {
                await vaultContract.cancelProposal({from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + NO_LEND_ERR))
                }
            })
        })
        // TODO: test liquidateLoan and returnLoan? need stub
    })
})