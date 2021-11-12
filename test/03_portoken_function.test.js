const { expect } = require('chai');
const { ethers, web3 } = require('hardhat');

describe('PorToken Contract Functions Test', () => {
    let TokenFactory, TokenProxy, owner, alice, john, trump;
    let blockNumBefore, blockBefore, timestampBefore;

    beforeEach(async () => {
        TokenFactory = await ethers.getContractFactory('PorToken');
        [owner, alice, john, trump, _] = await ethers.getSigners();

        blockNumBefore = await ethers.provider.getBlockNumber();
        blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    describe('Deploy Proxy Contract', () => {
        it('Should deploy proxy contract', async () => {
            TokenProxy = await upgrades.deployProxy(TokenFactory, {kind: 'uups'});
        });
    });

    describe('Blacklisted Test', () => {
        it('Should set trump account blacklisted: ', async () => {
            expect(await TokenProxy.isBlacklisted(trump.address)).to.be.false;
            await TokenProxy.blacklistAddress(trump.address, true);
            expect(await TokenProxy.isBlacklisted(trump.address)).to.be.true;
        });

        it('Should trump try to send token to Alice but fails: ', async () => {
            await expect(
                TokenProxy.connect(trump).transfer(alice.address, web3.utils.toWei('10'))
            ).to.be.revertedWith('SenderOrRecipientBlacklisted');
        });
    });
});