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

contract TeamVesting is Ownable {
  address public beneficiary;
  IERC20 public token;
  uint256 public vestingStartTime;
  uint256 public vestingEndTime;
  uint256 public totalTokens;
  uint256 public unlockedTokens;

  constructor(
    address _beneficiary,
    uint256 _vestingStartTime,
    uint256 _tokenAmount
  ) {
    require(vestingStartTime >= block.timestamp, "Vesting start time must be in the future");
    beneficiary = _beneficiary;
    vestingStartTime = _vestingStartTime;
    vestingEndTime = _vestingStartTime + 730 days; // 2 years vesting period
    totalTokens = _tokenAmount;
  }

  function unlockTokens() external {
    require(block.timestamp >= vestingStartTime, "Vesting has not started yet");

    uint256 currentTime = block.timestamp;
    uint256 timeElapsed = currentTime - vestingStartTime;

    // Ensure the vesting period is not over
    require(currentTime < vestingEndTime, "Vesting period has ended");

    // Calculate the amount of tokens to unlock based on the elapsed time
    uint256 tokensToUnlock = (totalTokens * timeElapsed) / (730 days);
    uint256 tokensUnlocked = tokensToUnlock - unlockedTokens;
        
    // Ensure there are tokens to unlock
    require(tokensUnlocked > 0, "No tokens available for unlock");

    // Update the unlocked tokens counter
    unlockedTokens = tokensToUnlock;

    // Transfer the unlocked tokens to the beneficiary
    require(token.transfer(beneficiary, tokensUnlocked), "Token transfer failed");
  }

  function updateTokenAddress(address _tokenAddress) external onlyOwner {
    token = IERC20(_tokenAddress);
  }
}
