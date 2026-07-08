require("@nomiclabs/hardhat-ethers");

module.exports = {
    solidity: {
        version: "0.8.22",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        regtest: {
            url: process.env.LAYERZERO_OFT_RPC_URL || "http://anvil-oft:8545",
            accounts: [
                process.env.LAYERZERO_OFT_DEPLOYER_KEY ||
                    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
            ],
        },
    },
};
