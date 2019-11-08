const TrstToken = artifacts.require("./TrstToken.sol");
const Vault = artifacts.require("./Vault.sol");

module.exports = function(deployer) {
  deployer.deploy(Vault, TrstToken.address)
};
