const { ethers, upgrades } = require("hardhat");

async function main() {
    // const proxyAddress = '0x9b5eDb7Dd25C704eaCA3d8Ae09282CCfDaeFCb63'; // proxy address testnet old
    // const proxyAddress = '0x9853839B8EE7D9F5B379Cd1660a00f1f220d8041'; // proxy address testnet
    const proxyAddress = '0x9000Cac49C3841926Baac5b2E13c87D43e51B6a4'; // proxy address mainnet

    const factoryContract = await ethers.getContractFactory("PorToken");
    console.log("Preparing proposal...");
    const prepare = await upgrades.prepareUpgrade(
        proxyAddress,
        factoryContract,
        {
            kind: 'transparent'
        }
    );
    console.log("Upgrade proposal created at:", prepare);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
;