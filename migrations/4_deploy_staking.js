const TrstToken = artifacts.require("./TrstToken.sol");
const Vault = artifacts.require("./Vault.sol");
const Staking = artifacts.require("./Staking.sol");

module.exports = function(deployer) {
  deployer.deploy(Staking, TrstToken.address, Vault.address)
};