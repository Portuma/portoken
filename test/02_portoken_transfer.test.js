const { expect } = require('chai');
const { ethers, web3 } = require('hardhat');
const {
    BN,           // Big Number support
    constants,    // Common constants, like the zero address and largest integers
    expectEvent,  // Assertions for emitted events
    expectRevert, // Assertions for transactions that should fail
} = require('@openzeppelin/test-helpers');

describe('Portuma Token Contract Transaction Test', () => {
    let TokenFactory, TokenProxy, owner, marketMaker, john, alice;
    let blockNumBefore, blockBefore, timestampBefore;

    // Expected Values Set
    let expected = [];

    beforeEach(async () => {
        TokenFactory = await ethers.getContractFactory('PorToken');
        [owner, marketMaker, john, alice, _] = await ethers.getSigners();

        blockNumBefore = await ethers.provider.getBlockNumber();
        blockBefore = await ethers.provider.getBlock(blockNumBefore);
        timestampBefore = blockBefore.timestamp;
    });

    describe('Deploy Proxy Contract', () => {
        it('Should deploy proxy contract', async () => {
            TokenProxy = await upgrades.deployProxy(TokenFactory, {kind: 'uups'});
            console.log("Proxy", TokenFactory.address);
        });
    });

    describe('Smoke Tests', () => {
        it('Should transfer 1000 tokens to john: ', async () => {
            await TokenProxy.transfer(john.address, web3.utils.toWei('1000'));
            expect(await TokenProxy.balanceOf(john.address)).to.be.eq(web3.utils.toWei('1000'));
        });

        it('Should transfer 1000 tokens to alice: ', async () => {
            // await expect(
            //     TokenProxy.transfer(alice.address, web3.utils.toWei('10000000000000000'))
            // ).to.be.revertedWith('InsufficientBalance');

            await TokenProxy.transfer(alice.address, web3.utils.toWei('1000'));
            expect(await TokenProxy.balanceOf(alice.address)).to.be.eq(web3.utils.toWei('1000'));
        });

        it('Should take 2000 token from owner: ', async () => {
            expect(await TokenProxy.balanceOf(owner.address)).to.be.eq(web3.utils.toWei('9999998000'));
        });

        it('Should try/fail transfer 50 tokens to alice from john: ', async () => {
            await expect(TokenProxy.connect(john).transfer(alice.address, web3.utils.toWei('50'))).to.be.revertedWith('TradingNotStarted');
        });
    });

    describe('Prepare for Transfers', () => {
        it('Should set Automated Market Maker Address: ', async () => {
            await TokenProxy.setAutomatedMarketMakerPair(marketMaker.address, true);

            console.log("AMM Address :" + marketMaker.address);
            console.log("AMM Balance :" + await TokenProxy.balanceOf(marketMaker.address));
        });

        it('Should transfer 1M tokens to MMA: ', async () => {
            await TokenProxy.transfer(marketMaker.address, web3.utils.toWei('1000000'));
            expect(await TokenProxy.balanceOf(marketMaker.address)).to.be.eq(web3.utils.toWei('1000000'));
        });

        it('Should activate trading: ', async () => {
            expect(await TokenProxy.getTradingStatus()).to.be.false;
            await TokenProxy.setTradingIsEnabled(true);
            expect(await TokenProxy.getTradingStatus()).to.be.true;
        });
    });

    describe('Scenario 1 - Wallet to Wallet', () => {
        it('Should transfer 100 tokens to alice from john: ', async () => {
            await TokenProxy.connect(john).transfer(alice.address, web3.utils.toWei('100'));
            // She Already had 1000 in wallet
            // %5 tax Taken 5
            // Alice recieves 95 Token
            // 0,000000054755475574 (54755475574 wei) Token from Reflection
            expect(await TokenProxy.balanceOf(alice.address)).to.be.eq('1095000000054755475574');
        });
    });

    describe('Scenario 2 - Buy From AMM ', () => {
        it('Should transfer 100 tokens to john from AMM: ', async () => {
            await TokenProxy.connect(marketMaker).transfer(john.address, web3.utils.toWei('100'));
            // John Already had 900,000000045004500472 in wallet
            // %5 tax Taken 5
            // John recieves 95 Token
            // 0,000000047267226299 (47267226299 wei) Token from Reflection
            expect(await TokenProxy.balanceOf(john.address)).to.be.eq('995000000092271726771');
        });
    });

    describe('Scenario 3 - Sell to AMM with Tiers ', () => {
        it('Should sell 100 tokens to AMM from john: at Tier[1]', async () => {
            await TokenProxy.connect(john).transfer(marketMaker.address, web3.utils.toWei('100'));
            // John Already had 995,000000092271726771 in wallet
            // sent 100 token to AMM
            // Tier-1 Tax: 30% Taken
            // AMM recieves 70 Token
            // AMM already had 999900
            expect(await TokenProxy.balanceOf(marketMaker.address)).to.be.eq('999970000000000000000000');
        });

        it('Should sell 100 tokens to AMM from alice: at Tier[2]', async () => {
            const diff = 1 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            await TokenProxy.connect(alice).transfer(marketMaker.address, web3.utils.toWei('100'));
            // Alice Already had 1095,000001201882689032 in wallet
            // sent 100 token to AMM
            // Tier-2 Tax: 20% Taken
            // AMM recieves 80 Token
            // AMM already had 999970
            expect(await TokenProxy.balanceOf(marketMaker.address)).to.be.eq(web3.utils.toWei('1000050'));
        });

        it('Should sell 100 tokens to AMM from alice: at Tier[3]', async () => {
            const diff = 21 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            await TokenProxy.connect(alice).transfer(marketMaker.address, web3.utils.toWei('100'));
            // Alice Already had 1095,000001201882689032 in wallet
            // sent 100 token to AMM
            // Tier-3 Tax: 10% Taken
            // AMM recieves 90 Token
            // AMM already had 1,000,050
            expect(await TokenProxy.balanceOf(marketMaker.address)).to.be.eq(web3.utils.toWei('1000140'));
        });

        it('Should sell 100 tokens to AMM from john: at After Tier[3]', async () => {
            const diff = 31 * 24 * 60 * 60;
            const tTime = timestampBefore - diff;

            await TokenProxy.resetStartTimestamp(tTime);
            await TokenProxy.connect(alice).transfer(marketMaker.address, web3.utils.toWei('100'));
            // Alice Already had 895,000001878450355634 in wallet
            // sent 100 token to AMM
            // Tier Ended - Normal Tax: 5% Taken
            // AMM recieves 90 Token
            // AMM already had 1,000,140
            expect(await TokenProxy.balanceOf(marketMaker.address)).to.be.eq(web3.utils.toWei('1000235'));
        });
    });
});