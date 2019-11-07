const Staking = artifacts.require("Staking");
const TrstToken = artifacts.require("TrstToken");
const ClintVault = artifacts.require("ClintVault");

contract('TrstToken', (accounts) => {
  it('should put 10000 Trst token in the first account', async () => {
    const trstContract = await ClintVault.deployed();
    const balance = await trstContract.balanceOf(accounts[0]);

    assert.equal(balance.valueOf(), 100000, "100000 wasn't in the first account");
  });
});