import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import chai, {expect} from "chai";
import {solidity} from "ethereum-waffle";
import {ethers, testUtils} from "hardhat";
import {PreSale} from "../types/PreSale";
import {PreSale__factory} from "../types/factories/PreSale__factory";
import {PreSaleFactory, SaleDetailStruct} from "../types/PreSaleFactory";
import {PreSaleFactory__factory} from "../types/factories/PreSaleFactory__factory";
import {parseEther} from "ethers/lib/utils";
import dayjs from "dayjs";
import {Router} from "../types/Router";
import RouterABI from "../abi/Router.json";
import {MockERC20} from "../types/MockERC20";
import {BionLock} from "../types/BionLock";
import {BionLock__factory} from "../types/factories/BionLock__factory";

chai.use(solidity);
const {assert} = chai;

describe("Launchpad", function () {
    let admin: SignerWithAddress;
    let projectOwner: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let preSaleImplementation: PreSale;
    let preSaleFactory: PreSaleFactory;
    let preSaleInitCodeHash: string;
    let bionLock: BionLock;

    let router: Router;
    let mockToken: MockERC20;

    let saleDetail: SaleDetailStruct;
    let preSale: PreSale;

    let now: number;

    before(async () => {
        [admin, projectOwner, user1, user2] = await ethers.getSigners();
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ admin", admin.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ projectOwner", projectOwner.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ user1", user1.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ user2", user2.address);

        router = <Router>await ethers.getContractAt(RouterABI, process.env.PANCAKE_ROUTER_ADDRESS!);

        preSaleInitCodeHash = ethers.utils.keccak256(
            (<PreSale__factory>await ethers.getContractFactory("PreSale")).getDeployTransaction().data!
        );
        bionLock = await (<BionLock__factory>await ethers.getContractFactory("BionLock")).deploy();
        preSaleImplementation = await (<PreSale__factory>await ethers.getContractFactory("PreSale")).deploy();
        preSaleFactory = await (<PreSaleFactory__factory>await ethers.getContractFactory("PreSaleFactory")).deploy(
            0,
            preSaleImplementation.address,
            parseEther("1"),
            bionLock.address
        );

        mockToken = <MockERC20>await (await ethers.getContractFactory("MockERC20")).deploy("MockToken", "MTK");
        await mockToken.mint(projectOwner.address, parseEther("100000000"));

        now = await testUtils.time.latest();

        saleDetail = {
            baseFee: 500,
            tokenFee: 0,
            feeTo: projectOwner.address,
            isQuoteETH: true,
            price: parseEther("0.0001"),
            startTime: now,
            endTime: now + 30 * 60,
            softCap: parseEther("100"),
            hardCap: parseEther("1000"),
            isAutoListing: true,
            listingPrice: parseEther("0.00012"),
            lpPercent: 6000,
            minPurchase: parseEther("0.1"),
            maxPurchase: parseEther("1000"),
            owner: projectOwner.address,
            router: router.address,
            token: mockToken.address,
            cycleDuration: 1,
            cycleReleasePercent: 1000,
            isBurnUnsold: false,
            isWhitelistEnabled: false,
            lockLPDuration: 1,
            quoteToken: "0x0000000000000000000000000000000000000000",
            tgeDate: dayjs().add(35, "minutes").unix(),
            tgeReleasePercent: 5000,
        };
    });

    // beforeEach(async () => {
    // });

    describe("CREATE SALE", async () => {
        it("should create sale with deterministic address", async () => {
            const salt1 = ethers.utils.formatBytes32String("62ce9ee7387cb5fa0a54c3bf");
            const deterministicAddress1 = await preSaleFactory.predictAddress(salt1);

            await expect(
                preSaleFactory.connect(projectOwner).create(saleDetail, salt1, {
                    value: parseEther("1.5"),
                })
            )
                .to.emit(preSaleFactory, "SaleCreated")
                .withArgs(projectOwner.address, deterministicAddress1, 0, salt1);

            preSale = <PreSale>await ethers.getContractAt("PreSale", deterministicAddress1);
        });
    });

    describe("PURCHASE IDO", async () => {
        it("should let user join IDO", async () => {
            await expect(preSale.connect(user1).purchase(parseEther("1000"))).to.revertedWith("NOT_BUY_IN_TOKEN");

            await preSale.connect(user1).purchaseInETH({value: parseEther("1000")});

            const user1PurchaseDetail = await preSale.purchaseDetails(user1.address);
            expect(user1PurchaseDetail.amount).to.eq(parseEther("1000"));

            expect(await testUtils.address.balance(preSale.address)).to.eq(parseEther("1000"));
        });

        it("should let user vesting", async () => {
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber());
        });
    });
});
