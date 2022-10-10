import {parseEther} from "ethers/lib/utils";
import {ethers} from "hardhat";
import {BionAvatar__factory} from "../types/factories/BionAvatar__factory";

async function main() {
    const [deployer] = await ethers.getSigners();

    const MAX_SUPPLY = 310;
    const START_INDEX = 310;
    const bionAvatar = await (<BionAvatar__factory>await ethers.getContractFactory("BionAvatar")).deploy(
        MAX_SUPPLY,
        START_INDEX
    );
    await bionAvatar.deployed();
    console.log("BionAvatar deployed to:", bionAvatar.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
