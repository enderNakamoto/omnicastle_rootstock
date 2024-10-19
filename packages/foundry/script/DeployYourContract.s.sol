//SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "../contracts/KingOfTheCastle.sol";
import "./DeployHelpers.s.sol";

contract DeployYourContract is ScaffoldETHDeploy {
  // use `deployer` from `ScaffoldETHDeploy`
  function run() external ScaffoldEthDeployerRunner {
    KingOfTheCastle kingOfTheCastle = new KingOfTheCastle();
    console.logString(
      string.concat(
        "KingOfTheCastle deployed at: ", vm.toString(address(kingOfTheCastle))
      )
    );
  }
}
