// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract ClashOfChickens is ERC20, ERC20Burnable, ERC20Snapshot, Ownable {
  constructor(
    address teamVestingContract,
    address testerRewardsContract,
    address gameRewardsContract
  ) ERC20("Clash Of Chickens", "CoC") {
    // Team gets 334k (3.32% of the total supply) locked for 2 years
    _mint(teamVestingContract, 334000 ether); 
    // Testers gets 66k (0.66% of the total supply) %100 Unlock
    _mint(testerRewardsContract, 66000 ether);
    // 9.6m for Game Rewards (96% of the total supply)
    _mint(gameRewardsContract, 9600000 ether);
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
