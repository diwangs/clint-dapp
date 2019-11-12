const BigNumber = require('bignumber.js'); // avoid overflow
// TODO: change all number to BigNumber?

const TrstToken = artifacts.require("TrstToken");

const PREFIX = "Returned error: VM Exception while processing transaction: ";
const AUTH_ERR = "You're not authorized"
const ZERO_ERR = "Destination address must not be 0"
const MISKIN_ERR = "Insufficient balance"

async function getGasCost(txinfo) {
	const tx = await web3.eth.getTransaction(txinfo.tx);
	const gasPrice = new BigNumber(tx.gasPrice)
	const gasUsed = new BigNumber(txinfo.receipt.gasUsed)
	return gasPrice.times(gasUsed);
}

contract('TrstToken', (accounts) => {
	const root = accounts[0]
	const rando = accounts[1]

	// constructor test
	it('should put 100000 mTrst in root', async () => {
		const trstContract = await TrstToken.deployed();
		
		const balance = await trstContract.balance(root);

		assert.equal(balance.valueOf(), 100000, "100000 mTrst wasn't in the root account");
	})

	describe("Administrative Methods", () => {
		describe("deposit (Fallback Function)", () => {
			it('should allow deposit', async () => {
				await TrstToken.deployed();
				const amount = web3.utils.toWei("1", "ether")
		
				const balanceBefore = await web3.eth.getBalance(TrstToken.address)
				await web3.eth.sendTransaction({
					from: root,
					to: TrstToken.address,
					value: amount
				})
				const balanceAfter = await web3.eth.getBalance(TrstToken.address)
		
				assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), amount, "Transaction unsuccesful")
			})
		})

		describe("withdraw", () => {
			it("should allow root to withdraw properly", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = web3.utils.toWei("0.5", "ether")
		
				const balanceBefore = new BigNumber(await web3.eth.getBalance(root))
				const txinfo = await trstContract.withdraw(amount, {from: root});
				const gasCost = await getGasCost(txinfo)
				const balanceAfter = new BigNumber(await web3.eth.getBalance(root))

				assert.equal(balanceAfter.minus(balanceBefore).plus(gasCost).valueOf(), amount, "Transaction unsucessful");
			})

			it("shouldn\'t allow rando to withdraw", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = web3.utils.toWei("0.5", "ether")
		
				try {
					await trstContract.withdraw(amount, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
				}
			})
		})

		describe("setPrice", () => {
			it("should allow price to be set by root", async () => {
				const trstContract = await TrstToken.deployed();
			
				await trstContract.setPrice(1100, {from: root})
				const price = await trstContract.price();
	
				assert.equal(price.valueOf(), 1100, "The price doesn't change");
			})

			it("shouldn\'t allow price to be set by rando", async () => {
				const trstContract = await TrstToken.deployed();
			
				try {
					await trstContract.setPrice(1000, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
				}
			})
		})

		describe("mint", () => {
			it("should allow root to mint", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = 1000000
			
				const balanceBefore = await trstContract.balance(root);
				await trstContract.mint(root, amount, {from: root})
				const balanceAfter = await trstContract.balance(root);
	
				assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), amount, "The balance doesn't change");
			})

			it("shouldn\'t allow rando to mint", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = 1000000
			
				try {
					await trstContract.mint(rando, amount, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
				}
			})
		})

		describe("burn", () => {
			it("should allow root to burn", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = 1000000
			
				const balanceBefore = await trstContract.balance(root);
				await trstContract.burn(root, amount, {from: root})
				const balanceAfter = await trstContract.balance(root);
	
				assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), -amount, "The balance doesn't change");
			})

			it("shouldn\'t allow rando to burn", async () => {
				const trstContract = await TrstToken.deployed();
				const amount = 1000000
			
				try {
					await trstContract.burn(root, amount, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
				}
			})
		})
	})

	describe("Operation Methods", () => {
		describe("transferFrom", () => {
			// TODO: add contract stub for intercontract transaction testing?
			it('should allow root to transfer properly', async () => {
				const trstContract = await TrstToken.deployed();
				
				const amount = 69;
				const balanceBefore = await trstContract.balance(rando);
				await trstContract.transferFrom(root, rando, amount, {from: root})
				const balanceAfter = await trstContract.balance(rando);
				
				assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), amount, "Transfer unsucessful")
			})
			
			it('shouldn\'t allow rando to transfer', async () => {
				const trstContract = await TrstToken.deployed();
				
				try {
					await trstContract.transferFrom(rando, root, 1, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
				} 
			})
			
			it('shouldn\'t allow root to transfer to address 0', async () => {
				const trstContract = await TrstToken.deployed();
				
				try {
					await trstContract.transferFrom(root, '0x0000000000000000000000000000000000000000', 1, {from: root})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + ZERO_ERR))
				}
			})
			
			it('shouldn\'t allow root to transfer with insufficient balance', async () => {
				const trstContract = await TrstToken.deployed();
				
				try {
					await trstContract.transferFrom(root, rando, 10000000, {from: root})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + MISKIN_ERR))
				}
			})
		})
		
		describe("redeem", () => {
			it('should allow rando to redeem properly', async () => {
				const trstContract = await TrstToken.deployed();
				
				const amount = 1;
				const price = await trstContract.price()
				
				const balanceBefore = new BigNumber(await web3.eth.getBalance(rando));
				
				const txinfo = await trstContract.redeem(amount, {from: rando})
				const gasCost = await getGasCost(txinfo)
				
				const balanceAfter = new BigNumber(await web3.eth.getBalance(rando));
				
				assert.equal(balanceAfter.minus(balanceBefore).plus(gasCost).valueOf(), amount * price.valueOf(), "Transfer unsucessful")
			})

			it('shouldn\'t allow rando to redeem with insufficient balance', async () => {
				const trstContract = await TrstToken.deployed();
				
				try {
					await trstContract.redeem(10000000, {from: rando})
				} catch (error) {
					assert(error, "Transaction successful")
					assert(error.message.startsWith(PREFIX + "revert " + MISKIN_ERR))
				}
			})
		})
	})
})
