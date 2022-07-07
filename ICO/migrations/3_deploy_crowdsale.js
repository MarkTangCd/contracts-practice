var Crowdsale = artifacts.require("Crowdsale");

module.exports = function (deployer) {
  deployer.deploy(Crowdsale, '0xB020c26a6FDCaF312DBcA7DF42BfBcd83fAf10f4', 3, 100, 1, '0xa6b8379fc2bc5FF3744bDbefbfD7873385510D27');
}