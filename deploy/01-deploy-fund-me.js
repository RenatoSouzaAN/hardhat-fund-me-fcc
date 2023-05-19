// hre = Hardhat Runtime Enviroment
// async function deployFunc(hre) {
//   console.log("Hi!");
// }
// module.exports.default = deployFunc;

// Syntax below is nearly identical, but the async function is anonymus

// module.exports = async (hre) => {
//   const { getNamedAccounts, deployments } = hre; }
//      hre.getNamedAccounts
//      hre.deployments

// "module.exposts" Below is the same thing as above but in one line

// const hlperConfig = require("../helper-hardhat-config")
// const networkConfig = helperConfig.networkConfig
// Or, we could just do as below
const {
  networkConfig,
  developmentChains,
} = require("../helper-hardhat-config");
const { network } = require("hardhat");

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, log } = deployments; // Pulling this two functions out of deployments
  const { deployer } = await getNamedAccounts();
  const chainId = network.config.chainId;
  const { verify } = require("../utils/verify");

  // if chainId is X use address Y, if chainId is Z use address A
  // const ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  let ethUsdPriceFeedAddress;
  if (developmentChains.includes(network.name)) {
    const ethUsdAggregator = await deployments.get("MockV3Aggregator");
    ethUsdPriceFeedAddress = ethUsdAggregator.address;
  } else {
    ethUsdPriceFeedAddress = networkConfig[chainId]["ethUsdPriceFeed"];
  }

  // if the contract doesn't exist, we deploy a minimal version of it for our local testing

  // when going for localhost or hardhat network we want to use a mock
  const args = [ethUsdPriceFeedAddress];
  const fundMe = await deploy("FundMe", {
    from: deployer,
    args: args, // put price feed address
    log: true,
    waitConfirmations: network.config.blockConfirmations || 1,
  });

  if (
    !developmentChains.includes(network.name) &&
    process.env.ETHERSCAN_API_KEY
  ) {
    await verify(fundMe.address, args);
  }

  log("----------------------------------------------");
};
module.exports.tags = ["all", "fundme"];
