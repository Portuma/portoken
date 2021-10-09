const { defender } = require("hardhat");

async function main() {
    const proxyAddress = ''; // proxy address

    const PortumaV2 = await ethers.getContractFactory("PotumaTokenV2");
    console.log("Preparing proposal...");
    const proposal = await defender.proposeUpgrade(proxyAddress, PortumaV2);
    console.log("Upgrade proposal created at:", proposal.url);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
;