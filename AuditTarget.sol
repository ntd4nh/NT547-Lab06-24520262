// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

// NT547 - Lab 06 - Hop dong rieng cua MSSV 24520262. KHONG deploy len mainnet.

interface IERC20Like {
    function transfer(address to, uint256 amount) external returns (bool);
}

contract PiggyBank_0262 {
    address public owner;
    mapping(address => uint256) public deposits;
    bool private entered;
    mapping(address => uint256) public parked;
    address payable internal immutable beneficiary;
    IERC20Like public rewardToken;
    mapping(address => uint256) public points;

    event Deposited(address indexed who, uint256 amount);

    modifier onlyOwner() {
        require(msg.sender == owner, "not owner");
        _;
    }

    modifier exclusive() {
        require(!entered, "reentrant");
        entered = true;
        _;
        entered = false;
    }

    constructor() {
        owner = msg.sender;
        beneficiary = payable(msg.sender);
    }

    function save() external payable {
        deposits[msg.sender] += msg.value;
        emit Deposited(msg.sender, msg.value);
    }

    function ownerWithdraw(uint256 amount) external onlyOwner {
        (bool ok, ) = payable(owner).call{value: amount}("");
        require(ok, "withdraw failed");
    }

    function updateOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "zero");
        owner = newOwner;
    }

    function depositSafe() external payable exclusive {
        parked[msg.sender] += msg.value;
    }

    function exitSafe() external exclusive {
        uint256 a = parked[msg.sender];
        parked[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: a}("");
        require(ok, "send failed");
    }

    function pullFunds() external {
        uint256 amount = deposits[msg.sender];
        require(amount > 0, "empty");
        deposits[msg.sender] = 0;
        (bool ok, ) = msg.sender.call{value: amount}("");
        require(ok, "send failed");
    }

    function forwardFees() external onlyOwner {
        beneficiary.transfer(address(this).balance / 2);
    }

    function setPayToken(address t) external onlyOwner {
        require(t != address(0), "zero");
        rewardToken = IERC20Like(t);
    }

    function convertRewards(uint256 amount) external {
        require(points[msg.sender] >= amount, "not enough");
        points[msg.sender] -= amount;
        require(rewardToken.transfer(msg.sender, amount), "token transfer failed");
    }

    function weekdayIndex() external view returns (uint256) {
        // UTC weekday for display only. No draw, payment or access check uses it.
        // slither-disable-next-line weak-prng
        return (block.timestamp / 1 days + 4) % 7;
    }
}
