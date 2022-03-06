import { expect } from "chai";
import { ethers } from "hardhat";
import {
  toWei,
  getBalance, fromWei
} from "./helpers/utils";
import {
  Token,
  Exchange,
} from "../typechain";
import {
  SignerWithAddress
} from "@nomiclabs/hardhat-ethers/signers";

describe("Exchange Contract", function () {
  let deployer: SignerWithAddress;
  let userA: SignerWithAddress;
  let userB: SignerWithAddress;
  let Token: Token;
  let Exchange: Exchange;

  beforeEach(async function(){
    [deployer, userA, userB] = await ethers.getSigners();

    Token = await (await ethers.getContractFactory("Token"))
        .deploy("DefiSwap Token", "DFS", toWei("1000000"));
    Exchange = await (await ethers.getContractFactory("Exchange"))
        .deploy(Token.address);

    await Token.transfer(userA.address, toWei("5000"));
    await Token.transfer(userB.address, toWei("5000"));
  });

  describe("Add Liquidity", function () {
    it("should add liquidity to exchange contract", async function () {
      await Token.connect(userA).approve(Exchange.address, toWei("500"));
      await Exchange.connect(userA).addLiquidity(toWei("500"), { value: toWei("100")});

      expect(await getBalance(Exchange.address)).to.equal(toWei("100"));
      expect(await Exchange.getReserve()).to.equal(toWei("500"));
    });
  });

  describe("Get Price", function (){

    it("should get the correct price", async function () {
      await Token.connect(userA).approve(Exchange.address, toWei("500"));
      await Exchange.connect(userA).addLiquidity(toWei("500"), { value: toWei("100")});

      //ETH per 1 token
      expect(
              (await Exchange.getEthAmount(toWei("10"))).toString()
      ).to.equal("1960784313725490196");

      //token per 1 ETH
      expect(
              (await Exchange.getTokenAmount(toWei("1"))).toString()
      ).to.equal("4950495049504950495");
    });

    it("should get the correct reserves", async function () {
      await Token.connect(userA).approve(Exchange.address, toWei("500"));
      await Exchange.connect(userA).addLiquidity(toWei("500"), { value: toWei("100")});

      const tokenReserve = await Exchange.getReserve();
      const etherReserve = await getBalance(Exchange.address);

      expect(fromWei(tokenReserve.toString())).to.equal("500.0")
      expect(fromWei(etherReserve.toString())).to.equal("100.0");
    });

  });

});
