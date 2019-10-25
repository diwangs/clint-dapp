const TrstToken = artifacts.require("./TrstToken.sol");
const ClintVault = artifacts.require("./ClintVault.sol");

module.exports = function(deployer) {
  deployer.deploy(TrstToken)
  deployer.deploy(ClintVault)
};
