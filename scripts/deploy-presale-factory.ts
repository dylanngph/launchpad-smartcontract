import {parseEther} from "ethers/lib/utils";
import {ethers} from "hardhat";
import {PreSaleFactory__factory} from "../types/factories/PreSaleFactory__factory";
import {PreSale__factory} from "../types/factories/PreSale__factory";

async function main() {
    const [deployer] = await ethers.getSigners();

    const BION_LOCK_ADDRESS = process.env.BION_LOCK_ADDRESS!;

    const preSaleImplementation = await (<PreSale__factory>await ethers.getContractFactory("PreSale")).deploy();
    console.log("PreSale implementation deployed to:", preSaleImplementation.address);

    const preSaleFactory = await (<PreSaleFactory__factory>await ethers.getContractFactory("PreSaleFactory")).deploy(
        0,
        preSaleImplementation.address,
        parseEther(process.env.PRESALE_CREATION_FEE!),
        BION_LOCK_ADDRESS
    );
    console.log("PreSaleFactory deployed to:", preSaleFactory.address);
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
