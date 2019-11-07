const BigNumber = require('bignumber.js'); // avoid overflow

const TrstToken = artifacts.require("TrstToken");

const PREFIX = "Returned error: VM Exception while processing transaction: ";
const AUTH_ERR = "You're not authorized"
const ZERO_ERR = "Destination address must not be 0"
const MISKIN_ERR = "Insufficient balance"

contract('TrstToken', (accounts) => {
  const root = accounts[0]
  const rando = accounts[1]


  // constructor test
  it('should put 100000 mTrst in root', async () => {
    const trstContract = await TrstToken.deployed();
    
    const balance = await trstContract.balance(root);

    assert.equal(balance.valueOf(), 100000, "100000 mTrst wasn't in the root account");
  })


  // transferFrom test
  it('shouldn\'t allow rando to transfer', async () => {
    const trstContract = await TrstToken.deployed();

    try {
      await trstContract.transferFrom(rando, root, 1, {from: rando})
    } catch (error) {
      assert(error, "Transaction successful")
      assert(error.message.startsWith(PREFIX + "revert " + AUTH_ERR))
    }
  });

  // TODO: add contract stub for intercontract transaction testing?
  it('should allow root to transfer properly', async () => {
    const trstContract = await TrstToken.deployed();
    
    const amount = 69;
    const balanceBefore = await trstContract.balance(rando);
    await trstContract.transferFrom(root, rando, amount, {from: root})
    const balanceAfter = await trstContract.balance(rando);

    assert.equal(balanceAfter.valueOf() - balanceBefore.valueOf(), amount, "Transfer unsucessful")
  });

  it('shouldn\'t allow root to transfer to address 0', async () => {
    const trstContract = await TrstToken.deployed();
    
    try {
      await trstContract.transferFrom(root, '0x0000000000000000000000000000000000000000', 1, {from: root})
    } catch (error) {
      assert(error, "Transaction successful")
      assert(error.message.startsWith(PREFIX + "revert " + ZERO_ERR))
    }
  });

  it('shouldn\'t allow root to transfer with insufficient balance', async () => {
    const trstContract = await TrstToken.deployed();
    
    try {
      await trstContract.transferFrom(root, rando, 10000000, {from: root})
    } catch (error) {
      assert(error, "Transaction successful")
      assert(error.message.startsWith(PREFIX + "revert " + MISKIN_ERR))
    }
  });

  it('should allow root to deposit', async () => {
    const trstContract = await TrstToken.deployed();
  });

  // redeem test
  it('should allow rando to redeem properly', async () => {
    const trstContract = await TrstToken.deployed();
    
    const amount = 1;
    const price = await trstContract.price()
    web3.eth.sendTransaction({
      from: accounts[0],
      to: TrstToken.address,
      value: web3.utils.toWei("1", "ether")
    })

    const balanceBefore = new BigNumber(await web3.eth.getBalance(rando));
    const txinfo = await trstContract.redeem(amount, {from: rando})
    const tx = await web3.eth.getTransaction(txinfo.tx);

    const gasPrice = new BigNumber(tx.gasPrice)
    const gasUsed = new BigNumber(txinfo.receipt.gasUsed)
    const gasCost = gasPrice.times(gasUsed);
    const balanceAfter = new BigNumber(await web3.eth.getBalance(rando));

    assert.equal(balanceAfter.minus(balanceBefore).plus(gasCost).valueOf(), amount * price.valueOf(), "Transfer unsucessful")
  });
});
