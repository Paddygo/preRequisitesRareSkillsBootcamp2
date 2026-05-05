//A payer deposits a certain amount of tokens into a contract, but the receiver can only withdraw 1/n tokens over the course of n days.

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract LinearVestingVault {
    IERC20 public immutable token;
    address public immutable beneficiary;

    uint256 public immutable vestingDuration;
    uint256 public startTimestamp;

    uint256 public totalDeposited;
    uint256 public totalWithdrawn;

    error AlreadyDeposited();
    error NothingToWithdraw();
    error NotBeneficiary();

    constructor(address _token, address _beneficiary, uint256 _vestingDuration) {
        require(_vestingDuration > 0, "invalid duration"); // Could be custom error instead to save gas
        token = IERC20(_token);
        beneficiary = _beneficiary;
        vestingDuration = _vestingDuration;
    }

    // ---- Deposit (one-time) ----

    function deposit(uint256 amount) external {
        if (totalDeposited != 0) revert AlreadyDeposited();
        require(amount > 0, "zero amount"); // // Could be custom error instead to save gas and be consistent
        token = IERC20(_token);

        totalDeposited = amount;
        startTimestamp = block.timestamp;

        token.transferFrom(msg.sender, address(this), amount);
    }

    // ---- Vesting math ----

    function vestedAmount() public view returns (uint256) {
        if (totalDeposited == 0) return 0;

        uint256 elapsed = block.timestamp - startTimestamp;
        if (elapsed >= vestingDuration) {
            return totalDeposited;
        }

        return (totalDeposited * elapsed) / vestingDuration;
    }

    function withdrawableAmount() public view returns (uint256) {
        return vestedAmount() - totalWithdrawn;
    }

    // ---- Withdraw ----

    function withdraw() external {
        if (msg.sender != beneficiary) revert NotBeneficiary();

        uint256 amount = withdrawableAmount();
        if (amount == 0) revert NothingToWithdraw();

        totalWithdrawn += amount;
        token.transfer(beneficiary, amount);
    }
}
