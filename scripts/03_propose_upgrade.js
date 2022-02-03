const { ethers, defender } = require("hardhat");

async function main() {
    // const proxyAddress = '0x9b5eDb7Dd25C704eaCA3d8Ae09282CCfDaeFCb63'; // proxy address testnet old
    // const proxyAddress = '0x9853839B8EE7D9F5B379Cd1660a00f1f220d8041'; // proxy address testnet
    const proxyAddress = '0x9000Cac49C3841926Baac5b2E13c87D43e51B6a4'; // proxy address mainnet

    const factoryContract = await ethers.getContractFactory("PorToken");
    console.log("Preparing proposal...");
    const proposal = await defender.proposeUpgrade(
        proxyAddress,
        factoryContract,
        {
            // kind: 'transparent',
            title: 'Upgrade to V1.0.6',
            description: 'Upgrade to V1.0.6',
            multisig: '0xd180f598c281a1B6AEa81Fc7A1268017a7D1EF5E',
            // proxyAdmin: '',
            // multisigType: 'Gnosis Multisig'
        }
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