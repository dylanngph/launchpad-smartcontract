import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import chai, {expect} from "chai";
import {solidity} from "ethereum-waffle";
import {parseEther} from "ethers/lib/utils";
import {ethers, testUtils} from "hardhat";
import PancakeFactoryABI from "../abi/PancakeFactory.json";
import PancakePairABI from "../abi/PancakePair.json";
import RouterABI from "../abi/Router.json";
import {BionLock} from "../types/BionLock";
import {BionLock__factory} from "../types/factories/BionLock__factory";
import {PreSaleFactory__factory} from "../types/factories/PreSaleFactory__factory";
import {PreSale__factory} from "../types/factories/PreSale__factory";
import {MockERC20} from "../types/MockERC20";
import {PancakeFactory} from "../types/PancakeFactory";
import {PancakePair} from "../types/PancakePair";
import {PreSale} from "../types/PreSale";
import {PreSaleFactory, SaleDetailStruct} from "../types/PreSaleFactory";
import {Router} from "../types/Router";

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
    let factory: PancakeFactory;
    let mockToken: MockERC20;

    let saleDetail: SaleDetailStruct;
    let preSale: PreSale;
    let pair: PancakePair;

    let NOW: number;

    const SALE_CREATION_FEE = parseEther(process.env.PRESALE_CREATION_FEE!);
    const PRICE = parseEther("0.0001");
    const SOFT_CAP = parseEther("500");
    const HARD_CAP = parseEther("1000");
    const LP_PERCENT = 60 * 100;
    const LISITNG_PRICE = parseEther("0.0002");
    const TGE_RELEASE_PERCENT = 50 * 100;
    const MIN_PURCHASE_AMOUNT = parseEther("0.1");
    const MAX_PURCHASE_AMOUNT = parseEther("1000");
    const USER1_PURCHASE_AMOUNT = parseEther("100");
    const USER2_PURCHASE_AMOUNT = parseEther("900");
    const BASE_FEE = 200;
    const TOKEN_FEE = 200;
    const CYCLE_DURATION = 86400;
    const CYCLE_RELEASE_PERCENT = 20 * 100;
    const LOCK_LP_DURATION = 86400 * 30;

    before(async () => {
        [admin, projectOwner, user1, user2] = await ethers.getSigners();
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ admin", admin.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ projectOwner", projectOwner.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ user1", user1.address);
        console.log("🚀 ~ file: Launchpad.ts ~ line 24 ~ before ~ user2", user2.address);

        router = <Router>await ethers.getContractAt(RouterABI, process.env.PANCAKE_ROUTER_ADDRESS!);
        factory = <PancakeFactory>await ethers.getContractAt(PancakeFactoryABI, await router.factory());

        preSaleInitCodeHash = ethers.utils.keccak256(
            (<PreSale__factory>await ethers.getContractFactory("PreSale")).getDeployTransaction().data!
        );
        bionLock = await (<BionLock__factory>await ethers.getContractFactory("BionLock")).deploy();
        preSaleImplementation = await (<PreSale__factory>await ethers.getContractFactory("PreSale")).deploy();
        preSaleFactory = await (<PreSaleFactory__factory>await ethers.getContractFactory("PreSaleFactory")).deploy(
            0,
            preSaleImplementation.address,
            SALE_CREATION_FEE,
            bionLock.address
        );

        mockToken = <MockERC20>await (await ethers.getContractFactory("MockERC20")).deploy("MockToken", "MTK");
        await mockToken.mint(projectOwner.address, parseEther("100000000"));
        await mockToken.connect(projectOwner).approve(preSaleFactory.address, ethers.constants.MaxUint256);

        NOW = await testUtils.time.latest();

        saleDetail = {
            baseFee: BASE_FEE,
            tokenFee: TOKEN_FEE,
            feeTo: projectOwner.address,
            isQuoteETH: true,
            price: PRICE,
            startTime: NOW,
            endTime: NOW + 30 * 60,
            softCap: SOFT_CAP,
            hardCap: HARD_CAP,
            isAutoListing: true,
            listingPrice: LISITNG_PRICE,
            lpPercent: LP_PERCENT,
            minPurchase: MIN_PURCHASE_AMOUNT,
            maxPurchase: MAX_PURCHASE_AMOUNT,
            owner: projectOwner.address,
            router: router.address,
            token: mockToken.address,
            cycleDuration: CYCLE_DURATION,
            cycleReleasePercent: CYCLE_RELEASE_PERCENT,
            isBurnUnsold: false,
            isWhitelistEnabled: false,
            lockLPDuration: LOCK_LP_DURATION,
            quoteToken: "0x0000000000000000000000000000000000000000",
            tgeDate: NOW + 35 * 60,
            tgeReleasePercent: TGE_RELEASE_PERCENT,
        };

        console.log("🚀 ~ file: Launchpad.ts ~ line 73 ~ before ~ saleDetail", saleDetail);
    });

    // beforeEach(async () => {
    // });

    describe("CREATE SALE", async () => {
        it("should create sale with deterministic address", async () => {
            const salt1 = ethers.utils.formatBytes32String("62ce9ee7387cb5fa0a54c3bf");
            const deterministicAddress1 = await preSaleFactory.predictAddress(salt1);
            const totalTokensRequired = HARD_CAP.div(PRICE)
                .add(HARD_CAP.mul(LP_PERCENT).div(10000).div(LISITNG_PRICE))
                .add(HARD_CAP.mul(BASE_FEE).div(10000).div(PRICE))
                .mul(parseEther("1"));
            console.log("🚀 ~ file: Launchpad.ts ~ line 120 ~ it ~ totalTokensRequired", totalTokensRequired);

            await expect(
                preSaleFactory.connect(projectOwner).create(saleDetail, salt1, {
                    value: SALE_CREATION_FEE,
                })
            )
                .to.emit(preSaleFactory, "SaleCreated")
                .withArgs(projectOwner.address, deterministicAddress1, 0, salt1);

            expect(await mockToken.balanceOf(deterministicAddress1)).to.be.equal(totalTokensRequired);

            preSale = <PreSale>await ethers.getContractAt("PreSale", deterministicAddress1);
        });
    });

    describe("PURCHASE IDO", async () => {
        it("should let user join IDO", async () => {
            await expect(preSale.connect(user1).purchase(USER1_PURCHASE_AMOUNT)).to.revertedWith("NOT_BUY_IN_TOKEN");

            await preSale.connect(user1).purchaseInETH({value: USER1_PURCHASE_AMOUNT});

            const user1PurchaseDetail = await preSale.purchaseDetails(user1.address);
            expect(user1PurchaseDetail.amount).to.eq(USER1_PURCHASE_AMOUNT);

            expect(await testUtils.address.balance(preSale.address)).to.eq(USER1_PURCHASE_AMOUNT);

            await preSale.connect(user2).purchaseInETH({value: USER2_PURCHASE_AMOUNT});
        });

        it("should let owner finalize sale", async () => {
            const currentCap = await preSale.currentCap();
            await expect(() => preSale.connect(projectOwner).finalizeInETH()).changeEtherBalance(
                projectOwner,
                currentCap.sub(currentCap.mul(LP_PERCENT).div(10000))
            );

            pair = <PancakePair>(
                await ethers.getContractAt(
                    PancakePairABI,
                    await factory.getPair(mockToken.address, await router.WETH())
                )
            );

            expect(await pair.balanceOf(bionLock.address)).to.gt(0);
            expect(await pair.balanceOf(projectOwner.address)).to.eq(0);
        });

        it("should let user vesting", async () => {
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber());

            const claimableToken = await preSale.calcClaimableTokenAmount(user1.address);
            console.log("🚀 ~ file: Launchpad.ts ~ line 159 ~ it ~ claimableToken", claimableToken);
            const saleTokenBalance = await mockToken.balanceOf(preSale.address);
            console.log("🚀 ~ file: Launchpad.ts ~ line 161 ~ it ~ saleTokenBalance", saleTokenBalance);
            // claim tge
            await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
                mockToken,
                user1,
                USER1_PURCHASE_AMOUNT.mul(TGE_RELEASE_PERCENT).div(10000).mul(parseEther("1")).div(PRICE)
            );

            // claim first cycle
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION);
            await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
                mockToken,
                user1,
                USER1_PURCHASE_AMOUNT.mul(CYCLE_RELEASE_PERCENT).div(10000).mul(parseEther("1")).div(PRICE)
            );

            // claim second cycle
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 2);
            await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
                mockToken,
                user1,
                USER1_PURCHASE_AMOUNT.mul(CYCLE_RELEASE_PERCENT).div(10000).mul(parseEther("1")).div(PRICE)
            );

            // claim third cycle
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 3);
            await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
                mockToken,
                user1,
                USER1_PURCHASE_AMOUNT.mul(10 * 100)
                    .div(10000)
                    .mul(parseEther("1"))
                    .div(PRICE)
            );

            // // claim fourth cycle
            // await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 4);
            // await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
            //     mockToken,
            //     user1,
            //     USER1_PURCHASE_AMOUNT.mul(CYCLE_RELEASE_PERCENT).div(10000).mul(parseEther("1")).div(PRICE)
            // );

            // // claim fifth cycle
            // await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 5);
            // await expect(() => preSale.connect(user1).claim()).to.changeTokenBalance(
            //     mockToken,
            //     user1,
            //     USER1_PURCHASE_AMOUNT.mul(CYCLE_RELEASE_PERCENT).div(10000).mul(parseEther("1")).div(PRICE)
            // );

            // claim sixth cycle
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 6);
            await expect(preSale.connect(user1).claim()).to.revertedWith("NO_CLAIMABLE_TOKEN");

            // user 2 claim
            await testUtils.time.increaseTo((await preSale.tgeDate()).toNumber() + CYCLE_DURATION * 10);
            await expect(() => preSale.connect(user2).claim()).to.changeTokenBalance(
                mockToken,
                user2,
                USER2_PURCHASE_AMOUNT.mul(parseEther("1")).div(PRICE)
            );

            // finish sale
            expect(await mockToken.balanceOf(preSale.address)).to.be.equal(0);
        });

        it("should let owner unlock lp", async () => {
            await testUtils.time.increaseTo(NOW + LOCK_LP_DURATION * 2);
            const locks = await bionLock.lpLocksForUser(projectOwner.address);
            console.log("🚀 ~ file: Launchpad.ts ~ line 253 ~ it ~ locks", locks);
            await expect(() => bionLock.connect(projectOwner).unlock(locks[0].id)).to.changeTokenBalance(
                pair,
                projectOwner,
                locks[0].amount
            );
        });
    });
});
