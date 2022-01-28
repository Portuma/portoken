const { ethers, upgrades } = require("hardhat");

async function main() {
  const Portoken = await ethers.getContractFactory("PorToken");
  const Proxy = await upgrades.upgradeProxy("0x9000Cac49C3841926Baac5b2E13c87D43e51B6a4", Portoken, {kind: 'transparent'});

  console.log("POR upgraded");
  console.log("Your upgraded proxy is done!", Proxy.address)
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  })
;