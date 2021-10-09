const { expect } = require('chai');
const { ethers, web3 } = require('hardhat');

describe('Por Token Contract Test', () => {
    let TokenFactory, TokenProxy, owner, addr1, addr2;
    let blockNumBefore, blockBefore, timestampBefore;

    // Expected Values Set
    let expected = [];
    expected.tokenName = 'Portuma';
    expected.totalSupply = web3.utils.toWei('10000000000');
    expected.version = '1.0.0';
    expected.burnFee = '50';
    expected.holderFee = '50';
    expected.marketingFee = '400';
    expected.taxTiers = '24,504,720';
    expected.tier1 = [];
    expected.tier1.burnFee = '500';
    expected.tier1.holderFee = '1000';
    expected.tier1.marketingFee = '1500';
    expected.tier2 = [];
    expected.tier2.burnFee = '500';
    expected.tier2.holderFee = '500';
    expected.tier2.marketingFee = '1000';
    expected.tier3 = [];
    expected.tier3.burnFee = '100';
    expected.tier3.holderFee = '200';
    expected.tier3.marketingFee = '700';

    beforeEach(async () => {
        TokenFactory = await ethers.getContractFactory('PorToken');
        [owner, addr1, addr2, _] = await ethers.getSigners();

        blockNumBefore = await ethers.provider.getBlockNumber();
        blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    describe('Deploy Proxy Contract', () => {
        it('Should deploy proxy contract', async () => {
            TokenProxy = await upgrades.deployProxy(TokenFactory, {kind: 'uups'});
        });
    });

    describe('Assertion for Proxy Contract', () => {
        it('Should set correct name: ' + expected.tokenName, async () => {
            expect((await TokenProxy.name()).toString()).to.eq(expected.tokenName);
        });

        it('Should set correct Total Supply: ' + web3.utils.fromWei(expected.totalSupply, "ether"), async () => {
            expect(await TokenProxy.totalSupply()).to.be.eq(expected.totalSupply);
        });

        it('Should set correct version: ' + expected.version , async () => {
            expect(await TokenProxy.version()).to.be.eq(expected.version);
        });

        it('Should set the right owner: ', async () => {
            expect(await TokenProxy.owner()).to.be.eq(owner.address);
        });

        it('Should send the totalSupply to the owner', async () => {
            const ownerBalance = await TokenProxy.balanceOf(owner.address);
            console.log("Owner address: ", owner.address)
            expect(await TokenProxy.totalSupply()).to.be.eq(ownerBalance);
        });
    });

    describe('Check Fee Data', async () => {
        it('Should set correct burn fee: ' + expected.burnFee, async () => {
            const burnFee = await TokenProxy.getBurnFee();
            expect(burnFee).to.be.eq(expected.burnFee);
        });

        it('Should set correct holder fee: ' + expected.holderFee, async () => {
            const holderFee = await TokenProxy.getHolderFee();
            expect(holderFee).to.be.eq(expected.holderFee);
        });

        it('Should set correct marketing fee: ' + expected.marketingFee, async () => {
            const marketingFee = await TokenProxy.getMarketingFee();
            expect(marketingFee).to.be.eq(expected.marketingFee);
        });

        it('Should set correct Tax Tiers: ' + expected.taxTiers, async () => {
            const taxTiers = await TokenProxy.getTaxTiers();
            expect(taxTiers.toString()).to.be.eq(expected.taxTiers);
        });
    });

    describe('Sell Condition Fee Check by Tiers', async () => {
        it('Should set correct Burn Fee on Tier[1]: ' + expected.tier1.burnFee, async () => {
            const burnFee = await TokenProxy.getCurrentBurnFeeOnSale();
            expect(burnFee).to.be.eq(expected.tier1.burnFee);
        });

        it('Should set correct Holder Fee on Tier[1]: ' + expected.tier1.holderFee, async () => {
            const holderFee = await TokenProxy.getCurrentHolderFeeOnSale();
            expect(holderFee).to.be.eq(expected.tier1.holderFee);
        });

        it('Should set correct Marketing Fee on Tier[1]: ' + expected.tier1.marketingFee, async () => {
            const marketingFee = await TokenProxy.getCurrentMarketingFeeOnSale();
            expect(marketingFee).to.be.eq(expected.tier1.marketingFee);
        });

        it('Should set correct Burn Fee on Tier[2]: ' + expected.tier2.burnFee, async () => {
            const diff = 1 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            const burnFee = await TokenProxy.getCurrentBurnFeeOnSale();
            expect(burnFee).to.be.eq(expected.tier2.burnFee);
        });

        it('Should set correct Holder Fee on Tier[2]: ' + expected.tier2.holderFee, async () => {
            const diff = 1 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const holderFee = await TokenProxy.getCurrentHolderFeeOnSale();
            expect(holderFee).to.be.eq(expected.tier2.holderFee);
        });

        it('Should set correct Marketing Fee on Tier[2]: ' + expected.tier2.marketingFee, async () => {
            const diff = 1 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const marketingFee = await TokenProxy.getCurrentMarketingFeeOnSale();
            expect(marketingFee).to.be.eq(expected.tier2.marketingFee);
        });

        it('Should set correct Burn Fee on Tier[3]: ' + expected.tier3.burnFee, async () => {
            const diff = 21 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            const burnFee = await TokenProxy.getCurrentBurnFeeOnSale();
            expect(burnFee).to.be.eq(expected.tier3.burnFee);
        });

        it('Should set correct Holder Fee on Tier[3]: ' + expected.tier3.holderFee, async () => {
            const diff = 21 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const holderFee = await TokenProxy.getCurrentHolderFeeOnSale();
            expect(holderFee).to.be.eq(expected.tier3.holderFee);
        });

        it('Should set correct Marketing Fee on Tier[3]: ' + expected.tier3.marketingFee, async () => {
            const diff = 21 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const marketingFee = await TokenProxy.getCurrentMarketingFeeOnSale();
            expect(marketingFee).to.be.eq(expected.tier3.marketingFee);
        });
    });

    describe('After Sell Condition Fee Check', async () => {
        it('Should set correct Burn Fee after Tiers: ' + expected.burnFee, async () => {
            const diff = 30 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            const burnFee = await TokenProxy.getCurrentBurnFeeOnSale();
            expect(burnFee).to.be.eq(expected.burnFee);
        });

        it('Should set correct Holder Fee after Tiers: ' + expected.holderFee, async () => {
            const diff = 30 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const holderFee = await TokenProxy.getCurrentHolderFeeOnSale();
            expect(holderFee).to.be.eq(expected.holderFee);
        });

        it('Should set correct Marketing after Tiers: ' + expected.marketingFee, async () => {
            const diff = 30 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);

            const marketingFee = await TokenProxy.getCurrentMarketingFeeOnSale();
            expect(marketingFee).to.be.eq(expected.marketingFee);
        });
    });
});