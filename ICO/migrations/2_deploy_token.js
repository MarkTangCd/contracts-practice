var MKTToken = artifacts.require("MKTToken");

module.exports = function (deployer) {
  deployer.deploy(MKTToken, 10000000);
}