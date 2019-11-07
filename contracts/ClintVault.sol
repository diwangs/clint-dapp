pragma solidity >=0.4.25 <0.6.0;

// ALL TOKEN UNIT MUST BE MILLITRST
import './TrstToken.sol';

contract ClintVault {
	address payable root;
    address stakeContractAddr;
    TrstToken tokenContract;

    uint interest; // How many wei per ether loaned per day?

    enum LoanStatus {IDLE, PROPOSED, LENT}
    mapping (address => LoanStatus) public loanStatus;
    mapping (address => uint) proposedLoan; // IN WEI
    mapping (address => uint) lentTimestamp; // TODO: change to block number?


    constructor(address payable _tokenContractAddr) public { // is it must be payable?
		root = msg.sender;
        tokenContract = TrstToken(_tokenContractAddr);
        tokenContract.setVaultContractAddr(address(this));

		interest = 1;
	}


    modifier onlyRoot() {
        require(msg.sender == root, "You're not authorized");
        _;
    }

    modifier onlyStakeContract() {
        require(msg.sender == stakeContractAddr, "You're not authorized");
        _;
    }


    // *** operation methods ***
    function proposeLoan(uint _value) external {
        // TODO: check values?
        proposedLoan[msg.sender] = _value;
        loanStatus[msg.sender] = LoanStatus.PROPOSED;
    }

    function liquidateLoan(address payable _candidate) external onlyStakeContract payable {
        // send ether from root to _candidate
        _candidate.transfer(proposedLoan[_candidate]);

        // change loanStatus and lentTimestamp
        loanStatus[_candidate] = LoanStatus.LENT;
        lentTimestamp[_candidate] = block.timestamp;
    }

    function returnLoan() external payable {
        require(loanStatus[msg.sender] == LoanStatus.LENT, "We're currently not lending you anything");
        // TODO: calculate and charge interest
        require(msg.value == proposedLoan[msg.sender], "Uang pas donk");

        // receive eth is done at the background
        cancelLoan(msg.sender);
        tokenContract.transferFrom(root, msg.sender, 10000); // TODO: change to actual incentive
    }


    // *** administrative methods ***
    function cancelLoanOf(address _candidate) external onlyRoot {
        cancelLoan(_candidate);
    }

    function setInterest(uint _value) external onlyRoot {
        interest = _value;
    }

    function() external payable {} // fallback function, used to deposit ETH

    function withdraw(uint _value) external onlyRoot {
        root.transfer(_value);
    }

    function setStakeContractAddr(address _address) external {
        require(stakeContractAddr == address(0), "Address has been set");
        stakeContractAddr = _address;
    }


    // *** private methods ***
    function cancelLoan(address _candidate) private {
        delete proposedLoan[_candidate];
        delete loanStatus[_candidate];
        delete lentTimestamp[_candidate];
    }
}
