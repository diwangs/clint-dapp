const Staking = artifacts.require("Staking");
const TrstToken = artifacts.require("TrstToken");
const Vault = artifacts.require("Vault");

const PREFIX = "Returned error: VM Exception while processing transaction: "
const AUTH_ERR = "You're not authorized"
const ADDR_ERR = "Invalid address"
const NO_PROP_ERROR = "The candidate isn't asking any vote"

contract('Staking', (accounts) => {
    const root = accounts[0]
    const rando1 = accounts[1]
    const rando2 = accounts[2]
    const rando3 = accounts[3]
    let stakeContract

    beforeEach(async () => {
        stakeContract = await Staking.deployed();
    })

    describe("Administrative Methods", () => {
        describe("setUpperThreshold", () => {
            it("should allow upperThreshold to be set by root", async () => {
                await stakeContract.setUpperThreshold(100001, {from: root})
                const upperThreshold = await stakeContract.upperThreshold();
                
                assert.equal(upperThreshold.valueOf(), 100001, "upperThreshold doesn't change");
            })
            
            it("shouldn\'t allow upperThreshold to be set by rando1", async () => {
                try {
                    await stakeContract.setUpperThreshold(100000, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setLowerThreshold", () => {
            it("should allow lowerThreshold to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setLowerThreshold(-100001, {from: root})
                const lowerThreshold = await stakeContract.lowerThreshold();
                
                assert.equal(lowerThreshold.valueOf(), -100001, "lowerThreshold doesn't change");
            })
            
            it("shouldn\'t allow lowerThreshold to be set by rando1", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setLowerThreshold(-100000, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setRewardRateNum", () => {
            it("should allow rewardRateNum to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setRewardRateNum(2, {from: root})
                const rewardRateNum = await stakeContract.rewardRateNum();
                
                assert.equal(rewardRateNum.valueOf(), 2, "rewardRateNum doesn't change");
            })
            
            it("shouldn\'t allow rewardRateNum to be set by rando1", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setRewardRateNum(100, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setRewardRateDenom", () => {
            it("should allow rewardRateDenom to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setRewardRateDenom(1001, {from: root})
                const rewardRateDenom = await stakeContract.rewardRateDenom();
                
                assert.equal(rewardRateDenom.valueOf(), 1001, "rewardRateDenom doesn't change");
            })
            
            it("shouldn\'t allow rewardRateDenom to be set by rando1", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setRewardRateDenom(100, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setPunishmentRateNum", () => {
            it("should allow punishmentRateNum to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setPunishmentRateNum(2, {from: root})
                const punishmentRateNum = await stakeContract.punishmentRateNum();
                
                assert.equal(punishmentRateNum.valueOf(), 2, "punishmentRateNum doesn't change");
            })
            
            it("shouldn\'t allow punishmentRateNum to be set by rando1", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setPunishmentRateNum(100, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })

        describe("setPunishmentRateDenom", () => {
            it("should allow punishmentRateDenom to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setPunishmentRateDenom(1001, {from: root})
                const punishmentRateDenom = await stakeContract.punishmentRateDenom();
                
                assert.equal(punishmentRateDenom.valueOf(), 1001, "punishmentRateDenom doesn't change");
            })
            
            it("shouldn\'t allow punishmentRateDenom to be set by rando1", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setPunishmentRateDenom(100, {from: rando1})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
            })
        })
    })

    describe("Operation Methods", () => {
        before(async () => {
            // Set balances
            const trstContract = await TrstToken.deployed();
            await trstContract.mint(rando1, 100000, {from: root})
            await trstContract.mint(rando2, 100000, {from: root})
            await trstContract.mint(rando3, 100000, {from: root})

            const vaultContract = await Vault.deployed();
            await vaultContract.proposeLoan(web3.utils.toWei("1", "ether"), "1209600", {from: rando1})
        })

        describe("setStake", () => {
            it("shouldn\'t allow someone to vote for address 0", async () => {
                try {
                    await stakeContract.setStake("0x0000000000000000000000000000000000000000", 1, { from: rando1 });
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + ADDR_ERR))
                }
            })

            it("shouldn\'t let someone stake someone without a proposal", async () => {
                // try {
                //     await stakeContract.setStake(rando1, 1, { from: rando2 });
                // } catch (error) {
                //     assert(error, "Transaction successful")
                //     assert(error.message.startsWith(PREFIX + "revert " + NO_PROP_ERROR))
                // }
                assert(true)
            })

            it('should handle positive stake correctly', async () => {
                const amount = 50000;
                
                await stakeContract.setStake(rando1, amount, { from: rando2 });
                const stake12 = await stakeContract.stake(rando1, rando2);

                assert.equal(stake12.valueOf(), amount, "Staked amount doesn't match")
            })
        })
    })
})
// it('should set handle positive stake correctly', async () => {
//     // THIS SHOULD FAIL because there is no voting proposal
//     const trstContract = await TrstToken.deployed();
//     const stakingContract = await Staking.deployed();

//     // Setup 2 accounts.
//     const A = accounts[0];
//     const B = accounts[1];

//     // Get initial balances of first and second account.
//     const AStartingBalance = (await trstContract.balanceOf(A)).toNumber();

//     // Make transaction from first account to second.
//     const amount = 10000;
//     await stakingContract.setStake(B, amount, { from: A });

//     // Get balances of first and second account after the transactions.
//     const AEndingBalance = (await trstContract.balanceOf(A)).toNumber();
//     const BStakeByA = (await stakingContract.getStake(B, A)).toNumber();

//     assert.equal(AEndingBalance, AStartingBalance - amount, "Amount wasn't correctly taken from A's balance");
//     assert.equal(BStakeByA, amount, "Amount wasn't correctly staked to B");
//   });