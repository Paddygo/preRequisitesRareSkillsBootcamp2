// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract LinearVestingVault {
    using SafeERC20 for IERC20;

    // ---- State ----

    IERC20 public immutable token;
    address public immutable beneficiary;

    uint256 public immutable vestingDuration;
    uint256 public startTimestamp;

    uint256 public totalDeposited;
    uint256 public totalWithdrawn;

    // ---- Errors ----

    error AlreadyDeposited();
    error NothingToWithdraw();
    error NotBeneficiary();
    error ZeroAmount();
    error InvalidDuration();
    error InvalidAddress();

    // ---- Events ----

    event Deposited(address indexed from, uint256 amount);
    event Withdrawn(address indexed to, uint256 amount);

    // ---- Constructor ----

    constructor(address _token, address _beneficiary, uint256 _vestingDuration) {
        if (_token == address(0) || _beneficiary == address(0)) {
            revert InvalidAddress();
        }
        if (_vestingDuration == 0) revert InvalidDuration();

        token = IERC20(_token);
        beneficiary = _beneficiary;
        vestingDuration = _vestingDuration;
    }

    // ---- Deposit (one-time) ----

    function deposit(uint256 amount) external {
        if (totalDeposited != 0) revert AlreadyDeposited();
        if (amount == 0) revert ZeroAmount();

        totalDeposited = amount;
        startTimestamp = block.timestamp;

        token.safeTransferFrom(msg.sender, address(this), amount);

        emit Deposited(msg.sender, amount);
    }

    // ---- Vesting math ----

    function vestedAmount() public view returns (uint256) {
        if (startTimestamp == 0) return 0;

        uint256 elapsed = block.timestamp - startTimestamp;

        if (elapsed >= vestingDuration) {
            return totalDeposited;
        }

        return (totalDeposited * elapsed) / vestingDuration;
    }

    function withdrawableAmount() public view returns (uint256) {
        return vestedAmount() - totalWithdrawn;
    }

    function remainingVestingTime() external view returns (uint256) {
        if (startTimestamp == 0) return vestingDuration;

        uint256 end = startTimestamp + vestingDuration;
        if (block.timestamp >= end) return 0;

        return end - block.timestamp;
    }

    // ---- Withdraw ----

    function withdraw() external {
        if (msg.sender != beneficiary) revert NotBeneficiary();

        uint256 amount = withdrawableAmount();
        if (amount == 0) revert NothingToWithdraw();

        totalWithdrawn += amount;

        token.safeTransfer(beneficiary, amount);

        emit Withdrawn(beneficiary, amount);
    }
}
