import { ethers } from "hardhat";
import {BigNumber} from "ethers";

export const getBalance = ethers.provider.getBalance;

export const fromWei = (value: string): string =>
  ethers.utils.formatEther(value);

export const toWei = (value: string): BigNumber =>
  ethers.utils.parseEther(value.toString());
