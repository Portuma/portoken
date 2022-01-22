const { ethers, defender } = require("hardhat");

async function main() {
    const proxyAddress = '0x9b5eDb7Dd25C704eaCA3d8Ae09282CCfDaeFCb63'; // proxy address testnet

    const factoryContract = await ethers.getContractFactory("PorToken");
    console.log("Preparing proposal...");
    const proposal = await defender.proposeUpgrade(
        proxyAddress,
        factoryContract,
        [
            title = 'Upgrade to V1.0.5',
            description = 'Upgrade to V1.0.5',
            // multisig = '0x74D638baa8c073C8528745D0F8fBCB6FCd0fC1a2',
            proxyAdmin = '0x5B2379a3983d6a428153F53E2898250807C6c8a8',
            // multisigType = 'Gnosis Multisig'
        ]
    );
    console.log("Upgrade proposal created at:", proposal.url);
}

main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
;