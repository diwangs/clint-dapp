pragma solidity >=0.4.25 <0.6.0;

import './TrstToken.sol';

contract ClintVault {
	address payable root;
    address stakeContractAddr;
    TrstToken tokenContract;

    uint interestMultiplier;
    uint interestDivisor;
    // rate = how many interestMultiplier per interestDivisor loaned
    uint lateMultiplier;
    uint lateDivisor;
    // additional rate if late = lateMultiplier / lateDivisor * late (seconds) * interestRate

    enum LoanStatus {IDLE, PROPOSED, LENT}
    mapping (address => LoanStatus) public loanStatus;
    mapping (address => uint) proposedLoan; // in Wei
    mapping (address => uint) deadlineDuration; // in s
    mapping (address => uint) lentTimestamp; // TODO: change to block number?


    constructor(address payable _tokenContractAddr) public {
		root = msg.sender;
        tokenContract = TrstToken(_tokenContractAddr);
        tokenContract.setVaultContractAddr(address(this));

		interestMultiplier = 1;
        interestDivisor = 1e3; // 0.1%
        lateMultiplier = 1;
        lateDivisor = 1209600; // 2 weeks
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



    // *** operation methods ***
    function proposeLoan(uint _value, uint _deadlineDuration) external {
        require(loanStatus[msg.sender] == LoanStatus.IDLE, "Settle your current proposal/lending first");
        // TODO: check _value?

        proposedLoan[msg.sender] = _value;
        deadlineDuration[msg.sender] = _deadlineDuration;
        loanStatus[msg.sender] = LoanStatus.PROPOSED;

        emit LoanStatusChange(msg.sender, LoanStatus.PROPOSED, true);
    }

    function cancelProposal() external {
        require(loanStatus[msg.sender] == LoanStatus.PROPOSED, "You don't have active proposal");

        _cancelLoan(msg.sender);

        emit LoanStatusChange(msg.sender, LoanStatus.IDLE, true);
    }

    function liquidateLoan(address payable _candidate) external onlyStakeContract payable {
        // send ether from root to _candidate
        _candidate.transfer(proposedLoan[_candidate]);

        // change loanStatus and lentTimestamp
        loanStatus[_candidate] = LoanStatus.LENT;
        lentTimestamp[_candidate] = block.timestamp;

        emit LoanStatusChange(_candidate, LoanStatus.LENT, true);
    }

    function returnLoan() external payable {
        require(loanStatus[msg.sender] == LoanStatus.LENT, "We're currently not lending you anything");
        uint effectiveMultiplier = interestMultiplier;
        // add interest if it's late
        if (block.timestamp > lentTimestamp[_candidate] + deadlineDuration) {
            uint late = block.timestamp - (lentTimestamp[_candidate] + deadlineDuration);
            effectiveMultiplier += lateMultiplier * late * effectiveMultiplier / lateDivisor;
        }
        uint interest = effectiveMultiplier * proposedLoan[msg.sender] / interestDivisor;
        require(msg.value < proposedLoan[msg.sender] + interest, "Not enough");

        // receive eth is done at the background
        _cancelLoan(msg.sender);
        emit LoanStatusChange(msg.sender, LoanStatus.IDLE, true);

        // Give Token incentive
        tokenContract.transferFrom(root, msg.sender, 100000); // TODO: change incentive mechanics
    }



    // *** administrative methods ***
    function cancelLoanOf(address _candidate) external onlyRoot {
        _cancelLoan(_candidate);

        emit LoanStatusChange(_candidate, LoanStatus.IDLE, false);
    }

    function setInterestMultiplier(uint _value) external onlyRoot {
        interestMultiplier = _value;
    }

    function setInterestDivisor(uint _value) external onlyRoot {
        interestDivisor = _value;
    }

    function setLateMultiplier(uint _value) external onlyRoot {
        lateMultiplier = _value;
    }

    function setLateDivisor(uint _value) external onlyRoot {
        lateDivisor = _value;
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
    function _cancelLoan(address _candidate) private {
        delete proposedLoan[_candidate];
        delete loanStatus[_candidate];
        delete deadlineDuration[_candidate];
        delete lentTimestamp[_candidate];
    }
}
