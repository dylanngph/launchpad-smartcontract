import {parseEther} from "ethers/lib/utils";
import {ethers} from "hardhat";
import {BionLock__factory} from "../types/factories/BionLock__factory";

async function main() {
    const [deployer] = await ethers.getSigners();

    const bionLock = await (<BionLock__factory>await ethers.getContractFactory("BionLock")).deploy();

    console.log("BionLock deployed to:", bionLock.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
