// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ZkChickens is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
  constructor(
    address teamVestingContract,
    address testerRewardsContract,
    address liquidityPool,
    address gameRewardsContract
  ) ERC20("Zk Chickens", "zkCHICKS") {
    // Team gets 332k (3.32% of the total supply) locked for 2 years
    _mint(teamVestingContract, 332000 ether); 
    // Testers gets 68k (0.68% of the total supply) %100 Unlock
    _mint(testerRewardsContract, 68250 ether);
    // 100k for LP (1% of the total supply)
    _mint(liquidityPool, 100000 ether);
    // 9.5m for Game Rewards (95% of the total supply)
    _mint(gameRewardsContract, 9499750 ether);
  }

  function snapshot() public onlyOwner {
    _snapshot();
  }

  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 amount)
    internal
    override(ERC20, ERC20Snapshot)
  {
    super._beforeTokenTransfer(from, to, amount);
  }
}
