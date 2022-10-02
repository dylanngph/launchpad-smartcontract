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
    let bionAvatar: BionAvatar;

    const START_INDEX = 300;
    const TOTAL_SUPPLY = 5;

    before(async function () {
        [admin, user1] = await ethers.getSigners();

        bionAvatar = await (<BionAvatar__factory>await ethers.getContractFactory("BionAvatar")).deploy(
            START_INDEX,
            TOTAL_SUPPLY
        );
    });

    describe("USER MINT", () => {
        it("should mint", async () => {
            // add whitelist
            await bionAvatar.connect(admin).addWhitelistMany([user1.address]);

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
                const tx = await bionAvatar.connect(user1).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user1).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user1).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
            {
                const tx = await bionAvatar.connect(user1).mint();
                const receipt = await tx.wait();
                const event = receipt.events?.find((e) => {
                    return e.event === "Transfer";
                });

                console.log("🚀 ~ file: BionAvatar.ts ~ line 31 ~ it ~ event", event?.args?.[2]?.toNumber());
            }
        });
    });
});
