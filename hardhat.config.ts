import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "hardhat-log-remover";
import {HardhatUserConfig, task} from "hardhat/config";
import "solidity-coverage";
import "hardhat-test-utils";

dotenv.config({
    path: `.env.${process.env.NODE_ENV ? process.env.NODE_ENV : "development"}`,
});

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
    const accounts = await hre.ethers.getSigners();

    for (const account of accounts) {
        console.log(account.address);
    }
});

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.9",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },
    networks: {
        bsc: {
            url: process.env.BSC_RPC,
            accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
        },
        hardhat: {
            // accounts: {
            //   mnemonic: "test test test test test test test test test test test junk",
            //   // count: 1000,
            // },
            // initialBaseFeePerGas: 0,
            forking: {
                url: "https://rpc.ankr.com/bsc",
                // blockNumber: 21329229,
            },
            // mining: {
            //   auto: true,
            //   interval: 3000,
            // },
            // chainId: 56,
        },
    },
    gasReporter: {
        enabled: process.env.REPORT_GAS !== undefined,
        currency: "USD",
    },
    etherscan: {
        apiKey: process.env.BSCSCAN_API_KEY,
    },
    abiExporter: {
        runOnCompile: true,
        flat: true,
    },
    typechain: {
        outDir: "types",
        externalArtifacts: [
            "./abi/Router.json",
            "./abi/PancakeFactory.json",
            "./abi/PancakePair.json",
            "./abi/WrappedBNB.json",
        ],
        alwaysGenerateOverloads: true,
    },
};

export default config;
