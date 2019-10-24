const TrstToken = artifacts.require("TrstToken");

contract('TrstToken', (accounts) => {
  it('should put 10000 Trst token in the first account', async () => {
    const trstContract = await TrstToken.deployed();
    const balance = await trstContract.balanceOf(accounts[0]);

    assert.equal(balance.valueOf(), 10000, "10000 wasn't in the first account");
  });

  it('should set handle positive stake correctly', async () => {
    const trstContract = await TrstToken.deployed();

    // Setup 2 accounts.
    const A = accounts[0];
    const B = accounts[1];

    // Get initial balances of first and second account.
    const AStartingBalance = (await trstContract.balanceOf(A)).toNumber();

    // Make transaction from first account to second.
    const amount = 10;
    await trstContract.setStake(B, amount, { from: A });

    // Get balances of first and second account after the transactions.
    const AEndingBalance = (await trstContract.balanceOf(A)).toNumber();
    const BStakeByA = (await trstContract.getStake(B, A)).toNumber();

    assert.equal(AEndingBalance, AStartingBalance - amount, "Amount wasn't correctly taken from A's balance");
    assert.equal(BStakeByA, amount, "Amount wasn't correctly staked to B");
  });

  it('should set handle negative stake correctly', async () => {
    const trstContract = await TrstToken.deployed();

    // Setup 2 accounts.
    const A = accounts[0];
    const B = accounts[1];

    // Get initial balances of first and second account.
    const AStartingBalance = (await trstContract.balanceOf(A)).toNumber();

    // Make transaction from first account to second.
    const amount = -10;
    await trstContract.setStake(B, amount, { from: A });

    // Get balances of first and second account after the transactions.
    const AEndingBalance = (await trstContract.balanceOf(A)).toNumber();
    const BStakeByA = (await trstContract.getStake(B, A)).toNumber();

    assert.equal(AEndingBalance, AStartingBalance, "Amount wasn't correctly taken from A's balance");
    assert.equal(BStakeByA, amount, "Amount wasn't correctly staked to B");
  });
});
