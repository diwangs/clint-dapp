const TrstToken = artifacts.require("./TrstToken.sol");
const ClintVault = artifacts.require("./ClintVault.sol");
const Staking = artifacts.require("./Staking.sol");

module.exports = function(deployer) {
  deployer.deploy(Staking, TrstToken.address, ClintVault.address)
};