// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC20 {
  function transfer(address to, uint256 value) external returns (bool);  
  function balanceOf(address account) external view returns (uint256);
}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor() {
        _transferOwnership(_msgSender());
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        _checkOwner();
        _;
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view virtual returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if the sender is not the owner.
     */
    function _checkOwner() internal view virtual {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
    }

    /**
     * @dev Leaves the contract without owner. It will not be possible to call
     * `onlyOwner` functions. Can only be called by the current owner.
     *
     * NOTE: Renouncing ownership will leave the contract without an owner,
     * thereby disabling any functionality that is only available to the owner.
     */
    function renounceOwnership() public virtual onlyOwner {
        _transferOwnership(address(0));
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Internal function without access restriction.
     */
    function _transferOwnership(address newOwner) internal virtual {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract CoC_GameRewards is Ownable {
  struct Round {
    uint256 startTime;
    uint256 burnAmount;
    uint256 rewardMultiplier;
    uint256 reward;
    uint256 rewardTransferTime;
    bool unlocked;
  }

  uint256 public roundLenght; // Adjustable
  uint256 public rewardMultiplier; // Adjustable
  uint256 public currentRoundNumber;
  uint256 public totalBurnAmount;
  uint256 public totalUnlockedRewards;
  uint256 public totalLockedAmount;

  address public rewardReceiver; // Adjustable
  address public itemContractAddress; // Adjustable
  IERC20 public token; // Adjustable

  mapping(uint256 => Round) public rounds;

  constructor(address receiverAddress, uint256 initialTokenAmount) {
    roundLenght = 10 minutes; // TEST
    currentRoundNumber = 1;
    rewardMultiplier = 2;

    rewardReceiver = receiverAddress;
    totalLockedAmount = initialTokenAmount;

    rounds[currentRoundNumber].startTime = block.timestamp; // TEST: Actual starting day: Monday
  }

  function updateRoundLength(uint256 newLength) external onlyOwner {
    roundLenght = newLength;
  }

  function updateRewardMultiplier(uint256 newMultiplier) external onlyOwner {
    rewardMultiplier = newMultiplier;
  }

  function updateRewardReceiver(address newReceiver) external onlyOwner {
    rewardReceiver = newReceiver;
  }

  function updateTokenAddress(address newAddress) external onlyOwner {
    token = IERC20(newAddress);
  }

  function updateItemAddress(address newAddress) external onlyOwner {
    itemContractAddress = newAddress;
  }

  function burnerInput(uint256 burnAmount) external {
    require(_msgSender() == itemContractAddress, "Only the item contract can call this function!");

    // Save burn amount
    totalBurnAmount += burnAmount;

    // If we still have rewards to unlock, execute roundCheck
    if (totalLockedAmount > 0) roundCheck(burnAmount);
  }

  function roundCheck(uint256 burnAmount) internal {
    // Get the difference
    uint256 increment = (block.timestamp - rounds[currentRoundNumber].startTime) / roundLenght;

    // If it's been less than a week, don't execute any code
    if (increment < 1) { 
      // If no increment, then just save the burn amount for the current week
      rounds[currentRoundNumber].burnAmount += burnAmount;
      return;
    }

    // If we have increment, then move on:
    
    // Save for the next round's time calculation
    uint256 currentStartTime = rounds[currentRoundNumber].startTime;

    // Calculate the reward for ending week (current)
    uint256 rewardAmount = rounds[currentRoundNumber].burnAmount * rewardMultiplier;

    // If there is not enough token left in the contract, then give what is left
    if (rewardAmount > totalLockedAmount) rewardAmount = totalLockedAmount;

    // Save current round rewrads.
    rounds[currentRoundNumber].reward = rewardAmount;
    rounds[currentRoundNumber].rewardMultiplier = rewardMultiplier;
    totalLockedAmount -= rewardAmount; // Reduce Remaining amount

    currentRoundNumber += increment; // Move on to the next round(s)
    
    // Save the last burn for the new week, because it happened when we are in the new week
    rounds[currentRoundNumber].burnAmount += burnAmount;

    // Set the new start time
    rounds[currentRoundNumber].startTime = currentStartTime + (increment * roundLenght);
  }

  function unlockRewards(uint256 roundNumber) external onlyOwner {
    // A round should have a starting time, reward, and should not be unlocked to be able to unlock rewards!
    require(
      rounds[roundNumber].startTime > 0 &&
      rounds[roundNumber].reward > 0 &&
      !rounds[roundNumber].unlocked,
      "Rewards have already been unlocked or there is no reward at all!"
    );

    // Mark the rewards as unlocked first
    rounds[roundNumber].unlocked = true;

    uint256 rewardAmount = rounds[roundNumber].reward;
    rounds[roundNumber].reward = 0;
    rounds[roundNumber].rewardTransferTime = block.timestamp;

    // Perform the state changes before interacting with other contracts
    totalUnlockedRewards += rewardAmount; // Total sent amount

    // Call the token contract to transfer rewards
    require(
      token.transfer(rewardReceiver, rewardAmount),
      "Unlock failed!"
    );
  }

  function readTime() external view returns (uint256) {
    return block.timestamp;
  }
}
