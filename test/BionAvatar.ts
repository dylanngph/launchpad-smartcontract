import {SignerWithAddress} from "@nomiclabs/hardhat-ethers/signers";
import chai, {expect} from "chai";
import {solidity} from "ethereum-waffle";
import {ethers} from "hardhat";
import {BionAvatar} from "../types/BionAvatar";
import {BionAvatar__factory} from "../types/factories/BionAvatar__factory";

chai.use(solidity);
const {assert} = chai;

describe("BionAvatar", function () {
    let admin: SignerWithAddress;
    let user1: SignerWithAddress;
    let user2: SignerWithAddress;
    let user3: SignerWithAddress;
    let user4: SignerWithAddress;
    let user5: SignerWithAddress;
    let user6: SignerWithAddress;
    let bionAvatar: BionAvatar;

    const START_INDEX = 300;
    const TOTAL_SUPPLY = 5;

    before(async function () {
        [admin, user1, user2, user3, user4, user5, user6] = await ethers.getSigners();

        bionAvatar = await (<BionAvatar__factory>await ethers.getContractFactory("BionAvatar")).deploy(
            TOTAL_SUPPLY,
            START_INDEX
        );
    });

    describe("USER MINT", () => {
        it("should mint", async () => {
            // add whitelist
            await bionAvatar
                .connect(admin)
                .addWhitelistMany([user1.address, user2.address, user3.address, user4.address, user5.address]);

            // user1 mint
            {
                const tx = await bionAvatar.connect(user1).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user2).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user3).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user4).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }

            await expect(bionAvatar.connect(user1).mint()).to.be.revertedWith("ALREADY_CLAIMED");
            await expect(bionAvatar.connect(user6).mint()).to.be.revertedWith("NOT_WHITELISTED");
            await bionAvatar.connect(user5).mint();
            await bionAvatar.connect(admin).addWhitelistMany([user6.address]);
            await expect(bionAvatar.connect(user6).mint()).to.be.revertedWith("MAX_SUPPLY_REACHED");
        });
    });
});
