pragma solidity >=0.4.25 <0.6.0;

// ALL TOKEN UNIT MUST BE MILLITRST

contract ClintVault {
	address _root;
    address _stakeContractAddr;

    uint256 interest; // How many wei for every ether loaned

    mapping (address => uint256) proposedLoan;
    enum LoanStatus {IDLE, PROPOSED, LENT}
    mapping (address => LoanStatus) loanStatus;


    constructor() public {
		_root = msg.sender;

		interest = 1;
	}


    modifier onlyRoot() {
        require(msg.sender == _root, "You're not root");
        _;
    }

    modifier onlyStakeContract() {
        require(msg.sender == _stakeContractAddr, "You're not a stake contract");
        _;
    }


    // *** GETTER ***
    function getProposedLoan(address _candidate) public view returns (uint256) {
        return proposedLoan[_candidate];
    }

    function getLoanStatus(address _candidate) public view returns (LoanStatus) {
        return loanStatus[_candidate];
    }


    // *** OPS ***
    function proposeLoan(uint256 _value) public returns (bool) {
        // checks?
        // change proposedLoan
        // change loanStatus
        return false;
    }

    function liquidateLoan(address _candidate) public onlyStakeContract returns (bool) {
        // send ether from root to _candidate
        // change loanStatus
        return false;
    }

    function returnLoan() public payable returns (bool) {
        // check if the sender has a loan
        // receive eth
        _cancelLoan(msg.sender);
        // give token incentive to msg.sender
        return false;
    }


    // *** ADMIN ***
    function cancelLoan(address _candidate) public onlyRoot returns (bool){
        return _cancelLoan(_candidate);
    }

    // TODO: Authorize this
    function setStakeContractAddr(address _address) public {
        _stakeContractAddr = _address;
    }


    // *** INTERNALS ***
    function _cancelLoan(address _candidate) private returns (bool) {
        delete proposedLoan[_candidate];
        delete loanStatus[_candidate];
        return true;
    }
}
