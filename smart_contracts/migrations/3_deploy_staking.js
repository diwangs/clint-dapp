const TrstToken = artifacts.require("./TrstToken.sol");
const ClintVault = artifacts.require("./ClintVault.sol");
const Staking = artifacts.require("./Staking.sol");

module.exports = function(deployer) {
    // deployer.deploy(TrstToken)
    // deployer.deploy(ClintVault)
    // Promise.all([TrstToken.deployed(), ClintVault.deployed()]).then((instances) => {
    //   deployer.deploy(Staking, instances[0], instances[1])
    // })
    deployer.deploy(Staking, TrstToken.address, ClintVault.address)
  };