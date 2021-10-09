const { ethers, upgrades } = require("hardhat");

async function main () {
  const factoryContract = await ethers.getContractFactory("PortumaToken");
  const proxyContract = await upgrades.deployProxy(factoryContract);
  await proxyContract.deployed();
  console.log("Proxy Contract deployed to:", proxyContract.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
;