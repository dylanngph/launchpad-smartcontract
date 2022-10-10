import * as dotenv from "dotenv";

import "@nomiclabs/hardhat-ethers";
import "@nomiclabs/hardhat-etherscan";
import "@nomiclabs/hardhat-waffle";
import "@openzeppelin/hardhat-upgrades";
import "@typechain/hardhat";
import "hardhat-abi-exporter";
import "hardhat-gas-reporter";
import "hardhat-log-remover";
import {HardhatUserConfig, task, types} from "hardhat/config";
import "solidity-coverage";
import "hardhat-test-utils";

dotenv.config({
    path: `.env.${process.env.NODE_ENV ? process.env.NODE_ENV : "development"}`,
});

task("flat", "Flattens and prints contracts and their dependencies (Resolves licenses)")
    .addOptionalVariadicPositionalParam("files", "The files to flatten", undefined, types.inputFile)
    .setAction(async ({files}, hre) => {
        let flattened = await hre.run("flatten:get-flattened-sources", {files});

        // Remove every line started with "// SPDX-License-Identifier:"
        flattened = flattened.replace(/SPDX-License-Identifier:/gm, "License-Identifier:");
        flattened = `// SPDX-License-Identifier: MIXED\n\n${flattened}`;

        // Remove every line started with "pragma experimental ABIEncoderV2;" except the first one
        flattened = flattened.replace(
            /pragma experimental ABIEncoderV2;\n/gm,
            (
                (i) => (m: any) =>
                    !i++ ? m : ""
            )(0)
        );
        console.log(flattened);
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
        okc: {
            url: process.env.OKC_RPC,
            accounts: [process.env.DEPLOYER_PRIVATE_KEY!],
        },
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
        apiKey: {
            bsc: process.env.BSCSCAN_API_KEY,
            bscTestnet: process.env.BSCSCAN_API_KEY,
            okc: process.env.OKCSCAN_API_KEY,
        } as any,
        customChains: [
            {
                network: "okc",
                chainId: 65,
                urls: {
                    apiURL: "https://www.oklink.com/api",
                    browserURL: "https://www.oklink.com/okc-test/",
                },
            },
        ],
    } as any,
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
