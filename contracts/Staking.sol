pragma solidity >=0.4.25 <0.6.0;

import './TrstToken.sol';
import './Vault.sol';

/**
@author Senapati Sang Diwangkara, from Affluent team

@title The Staking Contract

Staking is a contract that handles the voting part of the Clint system. It also
provides the means for administrator to set reward and punishment rate of the
correct/false stake

The logic in this contract is inspired by ERC-20's delegated transfer mechanism,
where voter -> spender and candidate -> owner

Among the 3 contracts, this contract must be deployed last, because it depends on the
other two contracts.
*/
contract Staking {
	address root;
    TrstToken tokenContract;
    Vault vaultContract;

	int public upperThreshold; // How much mTrst untill liquidation?
	int public lowerThreshold; // How much mTrst untill cancellation?
	uint public rewardRateNum;
	uint public rewardRateDenom;
	uint public punishmentRateNum;
	uint public punishmentRateDenom;

    /**
	* @dev A variable that states how much a voter has staked for a given candidate
	* Accessed by stake[candidate][voter]
	* In ERC-20, this is called `_allowed`
	*/
	mapping (address => mapping (address => int256)) public stake;
	mapping (address => int256) public totalStake;
	mapping (address => address[]) private stakers;

	constructor(address payable tokenContractAddr, address payable vaultContractAddr) public {
		root = msg.sender;

		upperThreshold = 100000;
		lowerThreshold = -100000;

		rewardRateNum = 1;
		rewardRateDenom = 1000; // 1 mTrst rewarded for every Trst staked
		punishmentRateNum = 1;
		punishmentRateDenom = 1000;

        tokenContract = TrstToken(tokenContractAddr);
        tokenContract.setStakeContractAddr(address(this));
        vaultContract = Vault(vaultContractAddr);
        vaultContract.setStakeContractAddr(address(this));
	}



	// *** Modifiers ***
	modifier onlyRoot() {
        require(msg.sender == root, "You're not authorized");
        _;
    }



	// *** Events ***
	event Vote(address indexed _candidate, address indexed _voter, int256 _value);
	event VoteConcluded(address indexed _candidate, bool voted);



	// *** Operation Methods ***
	/**
	* @dev Set the stake that a voter will vouch for a candidate
	*	In ERC-20, this is called `allowed` and instead of owner, spender will be set as input
	* 	NOTE: prevent race condition by setting the _value to 0 first before
	* 	setting it to the value we want. This must be done in the frontend.
	* @param _candidate The address whose voter stake to
	* @param _value The amount of stake
	*/
	function setStake(address payable _candidate, int256 _value) external {
		require(_candidate != address(0), "Invalid address");
		require(_candidate != msg.sender, "Invalid address");
        require(vaultContract.loanStatus(_candidate) == Vault.LoanStatus.PROPOSED, "The candidate isn't asking any vote");
        require(stake[_candidate][msg.sender] == 0, "You've already voted");
		// TODO: clamp mechanism

		stakers[_candidate].push(msg.sender);

		// Move balance accordingly
		totalStake[_candidate] += _value;
        tokenContract.transferFrom(msg.sender, root, _abs(_value));
		stake[_candidate][msg.sender] = _value;

		// Act if trust threshold exceeded
		_checkBallot(_candidate);

		emit Vote(_candidate, msg.sender, _value);
	}

	/**
	* @dev Cancel the sender's stake on a candidate
	* @param _candidate The address whom the sender staked to
	*/
	function cancelStake(address _candidate) external {
		uint256 absStake = _abs(stake[_candidate][msg.sender]);

		tokenContract.transferFrom(root, msg.sender, absStake);

		totalStake[_candidate] -= stake[_candidate][msg.sender];
		delete stake[_candidate][msg.sender];

		for (uint i = 0; i < stakers[_candidate].length; i++) {
			if (stakers[_candidate][i] == msg.sender) {
				delete stakers[_candidate][i];
				break;
			}
		}
	}



	// *** Administrative Methods ***
	/**
    * @dev Set the total stake's upper threshold. Can only be called by root
    * @param _value New upperThreshold value
    */
	function setUpperThreshold(int value) external onlyRoot {
		upperThreshold = value;
	}

	/**
    * @dev Set the total stake's lower threshold. Can only be called by root
    * @param _value New lowerThreshold value
    */
	function setLowerThreshold(int value) external onlyRoot {
		lowerThreshold = value;
	}

	/**
    * @dev Set the reward rate's numerator. Can only be called by root
    * @param _value New rewardRateNum value
    */
	function setRewardRateNum(uint value) external onlyRoot {
		rewardRateNum = value;
	}

	/**
    * @dev Set the reward rate's denominator. Can only be called by root
    * @param _value New rewardRateDenom value
    */
	function setRewardRateDenom(uint value) external onlyRoot {
		rewardRateDenom = value;
	}

	/**
    * @dev Set the punishment rate's numerator. Can only be called by root
    * @param _value New punishmentRateNum value
    */
	function setPunishmentRateNum(uint value) external onlyRoot {
		punishmentRateNum = value;
	}

	/**
    * @dev Set the punishment rate's denominator. Can only be called by root
    * @param _value New punishmentRateDenom value
    */
	function setPunishmentRateDenom(uint value) external onlyRoot {
		punishmentRateDenom = value;
	}



	// *** Internal Methods ***
	/**
    * @dev Check whether the votes are sufficient or not
    * @param _candidate The candidate who will be checked
    */
	function _checkBallot(address payable _candidate) private {
		if (totalStake[_candidate] >= upperThreshold || totalStake[_candidate] <= lowerThreshold) {
			bool voted = totalStake[_candidate] >= upperThreshold;

			// Liquidate loan
			if (voted) {
				vaultContract.liquidateLoan(_candidate);
			}

			_giveIncentive(_candidate, voted);
			_resetAllStakesOn(_candidate);

			emit VoteConcluded(_candidate, voted);
		}
	}

	/**
    * @dev Give incentive to the voters that voted for a candidate
    * @param _candidate The candidate whose voters will be acted upon
	* @param voted Whether the loan is successful or not
    */
	function _giveIncentive(address _candidate, bool voted) private {
		for (uint i = 0; i < stakers[_candidate].length; i++) {
            address staker = stakers[_candidate][i];
			bool isYes = stake[_candidate][staker] > 0;
			uint256 absStake = _abs(stake[_candidate][staker]);

			bool reward = (voted && isYes) || (!voted && !isYes); // XNOR
			// reward the yes, punish the no
			if (reward) {
				tokenContract.transferFrom(root, staker, rewardRateNum * absStake / rewardRateDenom);
			} else {
				tokenContract.transferFrom(staker, root, punishmentRateNum * absStake / punishmentRateDenom);
			}
		}
	}

	/**
    * @dev Reset all the stake that has been staked for a candidate
    * @param _candidate The candidate whose voters will be reseted
    */
	function _resetAllStakesOn(address _candidate) private {
		delete totalStake[_candidate];
		for (uint i = 0; i < stakers[_candidate].length; i++) {
            address staker = stakers[_candidate][i];
			uint256 absStake = _abs(stake[_candidate][staker]);
            tokenContract.transferFrom(root, staker, absStake);

			delete stake[_candidate][stakers[_candidate][i]];
		}
		delete stakers[_candidate];
	}

	/**
    * @dev Convert int to uint in an absolute manner
    * @param signed int value
	* @return uint value
    */
	function _abs(int signed) private pure returns (uint) {
		if (signed < 0) {
			return uint(-signed);
		} else {
			return uint(signed);
		}
	}
}