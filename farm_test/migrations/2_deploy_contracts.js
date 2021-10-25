const { BigNumber } = require("@ethersproject/bignumber");

const MasterChef = artifacts.require("MasterChef");

const FAVOR_TOKEN = "0x6Edf2d4937FaabeaA5c81302248AbDB722787feB";
//const DEV_ADDRESS = "0x83c4224A765dEE2Fc903dDed4f9A2046Ba7891E2";
const PANCAKESWAP_FARM = "0x73feaa1eE314F8c655E354234017bE2193C9E24E";
const CAKE_TOKEN = "0x0e09fabb73bd3ade0a17ecc321fd13a19e81ce82";
const TOKENS_PER_BLOCK = 40;
const START_BLOCK = 12080484;

module.exports = async function (deployer, network, accounts) {

    await deployer.deploy(MasterChef,
        FAVOR_TOKEN,
        PANCAKESWAP_FARM,
        CAKE_TOKEN,
        BigNumber.from(TOKENS_PER_BLOCK).mul(BigNumber.from(String(10**18))),
        BigNumber.from(START_BLOCK)
    );

};
