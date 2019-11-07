const TrstToken = artifacts.require("./TrstToken.sol");

module.exports = function(deployer) {
    deployer.deploy(TrstToken)
};