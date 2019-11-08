const Staking = artifacts.require("Staking");

const PREFIX = "Returned error: VM Exception while processing transaction: "
const AUTH_ERR = "You're not authorized"

contract('Staking', (accounts) => {
    root = accounts[0]
    rando = accounts[1]

    describe("Administrative Methods", () => {
        describe("setUpperThreshold", () => {
            it("should allow upperThreshold to be set by root", async () => {
                const stakeContract = await Staking.deployed();
                
                await stakeContract.setUpperThreshold(100001, {from: root})
                const upperThreshold = await stakeContract.upperThreshold();
                
                assert.equal(upperThreshold.valueOf(), 100001, "upperThreshold doesn't change");
            })
            
            it("shouldn\'t allow upperThreshold to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setUpperThreshold(100000, {from: rando})
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
            
            it("shouldn\'t allow lowerThreshold to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setLowerThreshold(-100000, {from: rando})
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
            
            it("shouldn\'t allow rewardRateNum to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setRewardRateNum(100, {from: rando})
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
            
            it("shouldn\'t allow rewardRateDenom to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setRewardRateDenom(100, {from: rando})
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
            
            it("shouldn\'t allow punishmentRateNum to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setPunishmentRateNum(100, {from: rando})
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
            
            it("shouldn\'t allow punishmentRateDenom to be set by rando", async () => {
                const stakeContract = await Staking.deployed();
                
                try {
                    await stakeContract.setPunishmentRateDenom(100, {from: rando})
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
                }
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