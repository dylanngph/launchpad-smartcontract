import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import chai, {expect} from "chai";
import {solidity} from "ethereum-waffle";
import {ethers} from "hardhat";
import {PreSale} from "../types/PreSale";
import {PreSale__factory} from "../types/factories/PreSale__factory";
import {PreSaleFactory} from "../types/PreSaleFactory";
import {PreSaleFactory__factory} from "../types/factories/PreSaleFactory__factory";
import {parseEther} from "ethers/lib/utils";

chai.use(solidity);
const {assert} = chai;

describe("Launchpad", function () {
    let admin: SignerWithAddress;
    let projectOwner: SignerWithAddress;
    let user: SignerWithAddress;
    let preSaleImplementation: PreSale;
    let preSaleFactory: PreSaleFactory;
    let preSaleInitCodeHash: string;

    before(async () => {
        [admin, projectOwner, user] = await ethers.getSigners();
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ admin", admin.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ projectOwner", projectOwner.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ user", user.address);

        preSaleInitCodeHash = ethers.utils.keccak256(
            (<PreSale__factory>await ethers.getContractFactory("PreSale")).getDeployTransaction().data!
        );
        preSaleImplementation = await (<PreSale__factory>await ethers.getContractFactory("PreSale")).deploy();
        preSaleFactory = await (<PreSaleFactory__factory>await ethers.getContractFactory("PreSaleFactory")).deploy(
            0,
            preSaleImplementation.address,
            parseEther("1")
        );
    });

    describe("CREATE SALE", async () => {
        const paddingEven = (number: string) => {
            return number.length % 2 === 0 ? number : `0${number}`;
        };

        it("should create sale with deterministic address", async () => {
            const saleDetail = {
                baseFee: 0,
                feeTo: admin.address,
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
                router: admin.address,
                softCap: 0,
                startTime: 0,
                token: admin.address,
                vestingPercents: [],
                vestingTimes: [],
            };

            // const salt1 = ethers.utils.keccak256(
            //     projectOwner.address + paddingEven("" + (await projectOwner.getTransactionCount()))
            // );
            const salt1 = ethers.utils.formatBytes32String("62ce9ee7387cb5fa0a54c3bf");
            console.log("🚀 ~ file: Launchpad.ts ~ line 71 ~ it ~ salt1", salt1);
            const deterministicAddress1 = await preSaleFactory.predictAddress(salt1);

            await expect(
                preSaleFactory.connect(projectOwner).create(saleDetail, salt1, {
                    value: parseEther("1.5"),
                })
            )
                .to.emit(preSaleFactory, "SaleCreated")
                .withArgs(projectOwner.address, deterministicAddress1, 0, salt1);

            const tx = await preSaleFactory.connect(projectOwner).create(saleDetail, salt1, {
                value: parseEther("1.5"),
            });

            // const receipt = await tx.wait();
            // console.log("receipt", JSON.stringify(receipt, null, 2));

            // const salt2 = ethers.utils.keccak256(
            //     projectOwner.address + paddingEven("" + (await projectOwner.getTransactionCount()))
            // );
            // const deterministicAddress2 = await preSaleFactory.predictAddress(salt2);

            // await expect(
            //     preSaleFactory.connect(projectOwner).create(saleDetail, salt2, {
            //         value: parseEther("1.5"),
            //     })
            // )
            //     .to.emit(preSaleFactory, "SaleCreated")
            //     .withArgs(projectOwner.address, deterministicAddress2, 0, salt2);

            // expect(deterministicAddress1).to.not.eq(deterministicAddress2);
        });
    });
});
