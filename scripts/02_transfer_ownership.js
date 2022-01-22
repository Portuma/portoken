const { upgrades } = require("hardhat");

async function main () {
    const gnosisSafe = '0x6FE01E7C733320DC7FCC0037272a6ac629DA5964'; // Wallet address
  
    console.log('Transferring ownership of ProxyAdmin...');
    // The owner of the ProxyAdmin can upgrade our contracts
    await upgrades.admin.transferProxyAdminOwnership(gnosisSafe);
    console.log('Transferred ownership of ProxyAdmin to:', gnosisSafe);
  }
  
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    })
;