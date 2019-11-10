const Staking = artifacts.require("Staking");
const TrstToken = artifacts.require("TrstToken");
const Vault = artifacts.require("Vault");

const PREFIX = "Returned error: VM Exception while processing transaction: "
const AUTH_ERR = "You're not authorized"
const ADDR_ERR = "Invalid address"
const DOUBLE_VOTE_ERR = "You've already voted"
const NO_PROP_ERR = "The candidate isn't asking any vote"

contract('Staking', (accounts) => {
    const root = accounts[0]
    const rando1 = accounts[1]
    const rando2 = accounts[2]
    const rando3 = accounts[3]
    const rando4 = accounts[4]
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
            await trstContract.mint(rando4, 100000, {from: root})

            const vaultContract = await Vault.deployed();
            await vaultContract.proposeLoan(web3.utils.toWei("1", "ether"), "1209600", {from: rando1})
            await vaultContract.proposeLoan(web3.utils.toWei("1", "ether"), "1209600", {from: rando2})

            await web3.eth.sendTransaction({
                from: root,
                to: Vault.address,
                value: web3.utils.toWei("5", "ether")
            })
        })

        describe("setStake", () => {
            it('should handle positive stake correctly', async () => {
                const amount = 50000;
                
                const totalStakeBefore = await stakeContract.totalStake(rando1)
                await stakeContract.setStake(rando1, amount, { from: rando2 })
                const totalStakeAfter = await stakeContract.totalStake(rando1)

                assert.equal(totalStakeAfter.valueOf() - totalStakeBefore.valueOf(), amount, "Staked amount doesn't match")
            })

            it('should handle negative stake correctly', async () => {
                const amount = -10000;
                
                const totalStakeBefore = await stakeContract.totalStake(rando1)
                await stakeContract.setStake(rando1, amount, { from: rando3 })
                const totalStakeAfter = await stakeContract.totalStake(rando1)

                assert.equal(totalStakeAfter.valueOf() - totalStakeBefore.valueOf(), amount, "Staked amount doesn't match")
            })
            
            it("shouldn\'t allow someone to vote for address 0", async () => {
                try {
                    await stakeContract.setStake("0x0000000000000000000000000000000000000000", 1, { from: rando1 });
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + ADDR_ERR))
                }
            })

            it("shouldn\'t allow someone to vote for themself", async () => {
                try {
                    await stakeContract.setStake(rando1, 1, { from: rando1 });
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + ADDR_ERR))
                }
            })

            it("shouldn\'t let someone stake someone without a proposal", async () => {
                try {
                    await stakeContract.setStake(rando2, 1, { from: rando1 });
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + NO_PROP_ERR))
                }
            })

            it("shouldn\'t let someone vote twice on the same person", async () => {
                try {
                    await stakeContract.setStake(rando1, 1, { from: rando2 });
                } catch (error) {
                    assert(error, "Transaction successful")
                    assert(error.message.startsWith(PREFIX + "revert " + DOUBLE_VOTE_ERR))
                }
            })

            it('should handle liquidation correctly', async () => {
                const totalStakeBefore = await stakeContract.totalStake(rando1)
                const upperThreshold = await stakeContract.upperThreshold()
                const amount = upperThreshold.valueOf() - totalStakeBefore.valueOf();
                
                const balanceBefore = await web3.eth.getBalance(rando1)
                await stakeContract.setStake(rando1, amount, { from: rando4 })
                const balanceAfter = await web3.eth.getBalance(rando1)

                assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), web3.utils.toWei("1", "ether"), "Staked amount doesn't match")
            })
        })

        describe("cancelStake", () => {
            it("should let staker cancel properly", async () => {
                const amount = -10000;
                
                const totalStakeBefore = await stakeContract.totalStake(rando2)
                await stakeContract.setStake(rando2, amount, { from: rando3 })
                await stakeContract.cancelStake(rando2, { from: rando3 })
                const totalStakeAfter = await stakeContract.totalStake(rando2)

                assert.equal(totalStakeAfter.toNumber(), totalStakeBefore.toNumber(), "Cancel error")
            })
        })
    })
})