const { ether } = require("@openzeppelin/test-helpers");
const fs = require("fs");
const path = require("path");

// smart contracts
const Favor = artifacts.require("Favor");

// test reward token params
const FavorName = "Favor";
const FavorSymbol = "FAVOR";
const FavorSupply = ether("5000000"); // 5,000,000 tokens
const FavorCap = ether("100000000");  // 100,000,000 tokens

module.exports = async function (deployer, network, accounts) {
    if (network === "test") return; // skip migrations if use test network

    // Favor deployment
    console.log("Favor deployment...");

    // deploy token
    await deployer.deploy(Favor, FavorName, FavorSymbol, FavorSupply, FavorCap);
    let Favor = await Favor.deployed();
    console.log("Favor address: ", Favor.address);

    // write addresses and ABI to files
    console.log("write addresses and ABI to files");
    const contractsAddresses = {
        Favor: Favor.address
    };

    const contractsAbi = {
        Favor: Favor.abi
    };

    const deployDirectory = `${__dirname}/../deployed`;
    if (!fs.existsSync(deployDirectory)) {
        fs.mkdirSync(deployDirectory);
    }

    fs.writeFileSync(path.join(deployDirectory, `${network}_addresses.json`), JSON.stringify(contractsAddresses, null, 2));
    fs.writeFileSync(path.join(deployDirectory, `${network}_abi.json`), JSON.stringify(contractsAbi, null, 2));
};