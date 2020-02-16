/* Generated by ts-generator ver. 0.0.8 */
/* tslint:disable */

/// <reference types="truffle-typings" />

import * as TruffleContracts from ".";

declare global {
  namespace Truffle {
    interface Artifacts {
      require(name: "CFD"): TruffleContracts.CFDContract;
      require(name: "Context"): TruffleContracts.ContextContract;
      require(name: "DAITokenMock"): TruffleContracts.DAITokenMockContract;
      require(name: "DownDai"): TruffleContracts.DownDaiContract;
      require(name: "ERC20"): TruffleContracts.ERC20Contract;
      require(name: "ERC20Burnable"): TruffleContracts.ERC20BurnableContract;
      require(name: "ERC20Detailed"): TruffleContracts.ERC20DetailedContract;
      require(name: "ERC20Mintable"): TruffleContracts.ERC20MintableContract;
      require(name: "IERC20"): TruffleContracts.IERC20Contract;
      require(
        name: "IMakerMedianizer"
      ): TruffleContracts.IMakerMedianizerContract;
      require(
        name: "IUniswapExchange"
      ): TruffleContracts.IUniswapExchangeContract;
      require(
        name: "IUniswapFactory"
      ): TruffleContracts.IUniswapFactoryContract;
      require(
        name: "MakerMedianizerMock"
      ): TruffleContracts.MakerMedianizerMockContract;
      require(name: "Migrations"): TruffleContracts.MigrationsContract;
      require(name: "MinterRole"): TruffleContracts.MinterRoleContract;
      require(name: "Ownable"): TruffleContracts.OwnableContract;
      require(name: "UpDai"): TruffleContracts.UpDaiContract;
      require(name: "UpSideDai"): TruffleContracts.UpSideDaiContract;
    }
  }
}
