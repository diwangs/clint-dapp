pragma solidity >=0.4.25 <0.6.0;

import './TrstToken.sol';
import './Staking.sol';

/**
@author Senapati Sang Diwangkara, from Affluent team

@title The Credit Vault Contract

Vault is a contract that handles the credit proposal, liquidation, and settlement.

Among the 3 contracts, this contract must be deployed second, because it depends on the
token contract but the staking contract depended on it.

*/
contract Vault {
	address payable root;
	address stakeContractAddr;
	TrstToken tokenContract;
	Staking stakeContract;

	uint public interestRateNum;
	uint public interestRateDenom;
	// interestRate = interestRateNum / interestRateDenom
	uint public latenessMultiplierNum;
	uint public latenessMultiplierDenom;
	// additional rate if late:
	// interestRate += latenessMultiplier * late (seconds) * interestRate

	enum LoanStatus {IDLE, PROPOSED, LENT}
	mapping (address => LoanStatus) public loanStatus;
	mapping (address => uint) public proposedLoan; // in Wei
	mapping (address => uint) public term; // promised duration to return the ETH, in seconds
	mapping (address => uint) public lentTimestamp; // UNIX timestamp when the proposal is granted
	// TODO: change to block number?
	address[] public stakable;
	mapping (address => uint) stakableIdx;



	constructor(address payable _tokenContractAddr) public {
		root = msg.sender;
		tokenContract = TrstToken(_tokenContractAddr);
		tokenContract.setVaultContractAddr(address(this));

		interestRateNum = 1;
		interestRateDenom = 1e3; // 0.1%
		latenessMultiplierNum = 1;
		latenessMultiplierDenom = 1209600; // 2 weeks
	}



	// *** Modifiers ***
	modifier onlyRoot() {
		require(msg.sender == root, "You're not authorized");
		_;
	}

	modifier onlyStakeContract() {
		require(msg.sender == stakeContractAddr, "You're not authorized");
		_;
	}



	// *** Events ***
	event LoanStatusChange(address indexed _address, LoanStatus to, bool isNormal);



	// *** Operation Methods ***
	/**
	* @dev Proposes a loan to the Clint system. Each address can only have 1 active lending
	*   process at a time
	* @param _value The amount of money to be lent
	* @param _term The promised duration to return the money (in seconds)
	*/
	function proposeLoan(uint _value, uint _term) external {
		require(loanStatus[msg.sender] == LoanStatus.IDLE, "You already have an active proposal");
		// TODO: check _value?

		proposedLoan[msg.sender] = _value;
		term[msg.sender] = _term;
		loanStatus[msg.sender] = LoanStatus.PROPOSED;

		uint len = stakable.push(msg.sender);
		stakableIdx[msg.sender] = len;

		emit LoanStatusChange(msg.sender, LoanStatus.PROPOSED, true);
	}

	/**
	* @dev Cancel a loan proposal. The sender must be in the PROPOSED state, i.e. have a
	*   proposed loan but not yet granted
	*/
	function cancelProposal() external {
		require(loanStatus[msg.sender] == LoanStatus.PROPOSED, "You don't have an active proposal");

		_cancelLoan(msg.sender);
		_removeStakable(msg.sender);

		emit LoanStatusChange(msg.sender, LoanStatus.IDLE, true);
	}

	/**
	* @dev Grant a loan to a proposer. Can only be called by stake contract
	* @param _candidate The proposer's address
	*/
	function liquidateLoan(address payable _candidate) external onlyStakeContract payable {
		// send ether from root to _candidate
		_candidate.transfer(proposedLoan[_candidate]);

		// change loanStatus and lentTimestamp
		loanStatus[_candidate] = LoanStatus.LENT;
		lentTimestamp[_candidate] = block.timestamp;

		_removeStakable(msg.sender);

		emit LoanStatusChange(_candidate, LoanStatus.LENT, true);
	}

	/**
	* @dev Return a loan to the Clint system. If the paid amount exceeds what is stated, the
	*   excess will be kept by the contract
	*/
	function returnLoan() external payable {
		require(loanStatus[msg.sender] == LoanStatus.LENT, "You don't have an active loan");

		uint effRateNum = interestRateNum;
		// add interest if it's late
		uint deadlineTimestamp = lentTimestamp[msg.sender] + term[msg.sender];
		if (block.timestamp > deadlineTimestamp) {
			uint lateness = block.timestamp - deadlineTimestamp;
			effRateNum += latenessMultiplierNum * lateness * effRateNum / latenessMultiplierDenom;
		}
		uint interest = effRateNum * proposedLoan[msg.sender] / interestRateDenom;
		require(msg.value < proposedLoan[msg.sender] + interest, "Insufficient amount");

		// receive eth is done at the background
		_cancelLoan(msg.sender);
		emit LoanStatusChange(msg.sender, LoanStatus.IDLE, true);

		// Give Token incentive
		tokenContract.transferFrom(root, msg.sender, 100000); // TODO: change incentive mechanics
		stakeContract._giveIncentive(msg.sender, true);
		stakeContract._resetAllStakesOn(msg.sender);
	}



	// *** Administrative Methods ***
	/**
	* @dev Manually cancels the loan process of a proposer. Can only be called by root
	* @param _candidate The proposer's address
	*/
	function cancelLoanOf(address _candidate) external onlyRoot {
		require(loanStatus[_candidate] != LoanStatus.IDLE, "_candidate doesn't have active loan or proposal");
		_cancelLoan(_candidate);
		if (loanStatus[_candidate] == LoanStatus.LENT) {
			stakeContract._giveIncentive(msg.sender, false);
		}
		stakeContract._resetAllStakesOn(_candidate);

		emit LoanStatusChange(_candidate, LoanStatus.IDLE, false);
	}

	/**
	* @dev Set the interest rate's numerator. Can only be called by root
	* @param _value New interestRateNum value
	*/
	function setInterestRateNum(uint _value) external onlyRoot {
		interestRateNum = _value;
	}

	/**
	* @dev Set the interest rate's denominator. Can only be called by root
	* @param _value New interestRateDenom value
	*/
	function setInterestRateDenom(uint _value) external onlyRoot {
		interestRateDenom = _value;
	}

	/**
	* @dev Set the lateness rate's numerator. Can only be called by root
	* @param _value New latenessMultiplierNum value
	*/
	function setLatenessMultiplierNum(uint _value) external onlyRoot {
		latenessMultiplierNum = _value;
	}

	/**
	* @dev Set the lateness rate's denominator. Can only be called by root
	* @param _value New latenessMultiplierDenom value
	*/
	function setLatenessMultiplierDenom(uint _value) external onlyRoot {
		latenessMultiplierDenom = _value;
	}

	/**
	* @dev Fallback function. Used to deposit ETH to the contract
	*/
	function() external payable {}

	/**
	* @dev Withdraw ETH from the contract into root's account. Can only be called by root
	* @param _value Withdrawal amount
	*/
	function withdraw(uint _value) external onlyRoot {
		root.transfer(_value);
	}

	/**
	* @dev Set the stake contract's address. Can only be called once
	* @param _address stake contract's address
	*/
	function setStakeContractAddr(address _address) external {
		require(stakeContractAddr == address(0), "Address has been set");
		stakeContractAddr = _address;
		stakeContract = Staking(_address);
	}



	// *** Private Methods ***
	/**
	* @dev A private method to clear the state of a loan proposer
	* @param _candidate The proposer's address
	*/
	function _cancelLoan(address _candidate) private {
		delete proposedLoan[_candidate];
		delete loanStatus[_candidate];
		delete term[_candidate];
		delete lentTimestamp[_candidate];
	}

	function _removeStakable(address candidate) private {
		uint index = stakableIdx[candidate];

		if (stakable.length > 1) {
			stakable[index] = stakable[stakable.length-1];
		}

		delete stakableIdx[candidate];
		stakable.length--; // Implicitly recovers gas from last element storage
	}
}
