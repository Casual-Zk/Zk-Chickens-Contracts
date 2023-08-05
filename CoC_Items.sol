// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Burnable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";

interface IERC20Burnable {
  function burnFrom(address account, uint256 amount) external;
}

interface IGameRewardsContract {
  function burnerInput(uint256 burnAmount) external;
}

contract CoC_Items is ERC1155, Ownable, ERC1155Burnable, ERC1155Supply {
  struct Item {
    bool isActive;
    uint256 mintCost;
  }

  IERC20Burnable public token;
  IGameRewardsContract public gameRewardsContract;

  mapping(uint256 => Item) public items;
  mapping(address => mapping(uint256 => uint256)) public mintedAmount; // account => id => amount
  mapping(address => mapping(uint256 => uint256)) public burnedAmount; // account => id => amount

  constructor(address tokenAddress, address gameRewardsContractAddress, uint256[] memory ids, uint256[] memory mintCosts) ERC1155("") {
    token = IERC20Burnable(tokenAddress);
    gameRewardsContract = IGameRewardsContract(gameRewardsContractAddress);

    for (uint256 i = 0; i < ids.length; i++){
      items[ids[i]].isActive = true;
      items[ids[i]].mintCost = mintCosts[i];
    }    
  }

  function mint(address account, uint256 id, uint256 amount, bytes memory data) public
  {
    require(items[id].isActive, "Item is not active!");

    // Burn tokens to mint item
    uint256 tokenAmount = amount * items[id].mintCost;
    token.burnFrom(_msgSender(), tokenAmount);

    // Let the Game Rewards Contract to know burn amount
    gameRewardsContract.burnerInput(tokenAmount);

    _mint(account, id, amount, data);

    // Save how many items this account minted
    mintedAmount[account][id] += amount;
  }

  function mintBatch(address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) public
  {
    uint256 tokenAmount = 0;

    for(uint i = 0; i < ids.length; i++){
      require(items[ids[i]].isActive, "Mint list contains an inactive item!");

      tokenAmount += amounts[i] * items[ids[i]].mintCost;

      // Save how many items this account minted
      mintedAmount[to][ids[i]] += amounts[i];
    }
    
    // Burn tokens to mint item
    token.burnFrom(_msgSender(), tokenAmount);

    // Let the Game Rewards Contract to know burn amount
    gameRewardsContract.burnerInput(tokenAmount);

    _mintBatch(to, ids, amounts, data);
  }

  function burn(address account, uint256 id, uint256 value) public virtual override {
    super.burn(account, id, value);

    burnedAmount[account][id] += value;
  }

  function burnBatch(address account, uint256[] memory ids, uint256[] memory values) public virtual override{
    super.burnBatch(account, ids, values);

    for(uint i = 0; i < ids.length; i++){
      burnedAmount[account][ids[i]] += values[i];
    }
  }

  // The following function is overrides required by Solidity.

  function _beforeTokenTransfer(address operator, address from, address to, uint256[] memory ids, uint256[] memory amounts, bytes memory data) internal override(ERC1155, ERC1155Supply)
  {
    super._beforeTokenTransfer(operator, from, to, ids, amounts, data);
  }

  function updateTokenAddress(address tokenAddress) external onlyOwner {
    token = IERC20Burnable(tokenAddress);
  }

  function updateGameRewardsAddress(address newAddress) external onlyOwner {
    gameRewardsContract = IGameRewardsContract(newAddress);
  }

  function updateMintCost(uint256 id, uint256 newCost) external onlyOwner {
    items[id].mintCost = newCost;
  }

  function setItemActivity(uint256 id, bool isActive) external onlyOwner {
    items[id].isActive = isActive;
  }

  function setURI(string memory newuri) public onlyOwner {
    _setURI(newuri);
  }
}
