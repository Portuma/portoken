const { ethers } = require("hardhat");

async function main() {
    // We get the contract to deploy
    const PresaleFactory = await ethers.getContractFactory("Presale");
    const PresaleContract = await PresaleFactory.deploy(2000000000, 400000000000, 1, 800, 20000000000000000n, 10000000000000000000n, 1637699400, 1637703000);

    console.log("Presale deployed to:", PresaleContract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })
;