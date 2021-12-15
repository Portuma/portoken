const { expect } = require('chai');
const { ethers, web3 } = require('hardhat');

describe('Por Token Presale Test', () => {
    let collectedWei = web3.utils.fromWei('700000000000000000');
    let oneToken = web3.utils.fromWei('400000000000');

    describe('Presale Claim Test', () => {
        token = (collectedWei * 1e18) / oneToken;
        
        console.log(token);
    });
});