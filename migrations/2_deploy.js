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
    let favor = await Favor.deployed();
    console.log("Favor address: ", favor.address);

    // write addresses and ABI to files
    console.log("write addresses and ABI to files");
    const contractsAddresses = {
        favor: favor.address
    };

    const contractsAbi = {
        favor: favor.abi
    };

    const deployDirectory = `${__dirname}/../deployed`;
    if (!fs.existsSync(deployDirectory)) {
        fs.mkdirSync(deployDirectory);
    }

    fs.writeFileSync(path.join(deployDirectory, `${network}_addresses.json`), JSON.stringify(contractsAddresses, null, 2));
    fs.writeFileSync(path.join(deployDirectory, `${network}_abi.json`), JSON.stringify(contractsAbi, null, 2));
};