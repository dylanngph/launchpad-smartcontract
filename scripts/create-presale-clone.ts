import {ethers} from "hardhat";
import {PreSaleFactory, SaleDetailStruct} from "../types/PreSaleFactory";
import PreSaleFactoryABI from "../abi/PreSaleFactory.json";
import {paddingEven} from "../utils";
import {parseEther} from "ethers/lib/utils";
import dayjs from "dayjs";

async function main() {
    const [deployer] = await ethers.getSigners();
    const projectOwner = deployer;
    console.log("🚀 ~ file: create-presale-clone.ts ~ line 10 ~ main ~ projectOwner", projectOwner.address);

    const preSaleFactory = <PreSaleFactory>(
        await ethers.getContractAt(PreSaleFactoryABI, process.env.PRESALE_FACTORY_ADDRESS!)
    );

    const mockDetail: SaleDetailStruct = {
        baseFee: 0,
        feeTo: deployer.address,
        isQuoteETH: true,
        tokenFee: 0,
        endTime: 0,
        hardCap: 0,
        isAutoListing: false,
        listingPrice: 0,
        lpPercent: 0,
        maxPurchase: 0,
        minPurchase: 0,
        owner: projectOwner.address,
        price: 0,
        router: deployer.address,
        softCap: 0,
        startTime: 0,
        token: deployer.address,
        tgeDate: dayjs().unix(),
        tgeReleasePercent: 5000,
        cycleDuration: 3600,
        cycleReleasePercent: 5000,
    };

    // const salt = ethers.utils.keccak256(
    //     projectOwner.address + paddingEven("" + (await projectOwner.getTransactionCount()))
    // );
    const salt = "0x3633323933383035613362366233353461353733363862620000000000000000";

    await preSaleFactory.connect(projectOwner).create(mockDetail, salt, {
        value: parseEther("0.1"),
    });

    console.log("PreSale created at:", await preSaleFactory.predictAddress(salt));
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
