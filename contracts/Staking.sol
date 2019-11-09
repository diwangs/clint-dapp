pragma solidity >=0.4.25 <0.6.0;

import './TrstToken.sol';
import './Vault.sol';

/**
@author Senapati Sang Diwangkara, from Affluent team

@title The Staking Contract
*
*	These following variable, events, and functions are used to let
*	someone (voter) to stake token on somebody else's behalf (candidate)
*
* 	Inspired by ERC-20's delegated transfer mechanism, where voter -> spender
*	and candidate -> owner
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
	event Granted(address indexed _candidate);



	// *** Operation Methods ***
	/**
	* @dev Set the stake that a voter will vouch for a candidate
	*	In ERC-20, this is called `allowed` and instead of owner, spender will be set as input
	* 	NOTE: prevent race condition by setting the _value to 0 first before
	* 	setting it to the value we want. This must be done in the frontend.
	* @param _candidate The address whose voter stake to
	* @param _value The amount of stake
	* @return a boolean indicating the set status
	*/
	function setStake(address payable _candidate, int256 _value) external {
		require(_candidate != address(0), "Invalid address");
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

	function cancelStake(address _candidate) external {
		uint256 absStake = _abs(stake[_candidate][msg.sender]);

		tokenContract.transferFrom(root, msg.sender, absStake);

		delete stake[_candidate][msg.sender];
		for (uint i = 0; i < stakers[_candidate].length; i++) {
			if (stakers[_candidate][i] == msg.sender) {
				delete stakers[_candidate][i];
				break;
			}
		}
	}



	// *** Administrative Methods ***
	function setUpperThreshold(int value) external onlyRoot {
		upperThreshold = value;
	}

	function setLowerThreshold(int value) external onlyRoot {
		lowerThreshold = value;
	}

	function setRewardRateNum(uint value) external onlyRoot {
		rewardRateNum = value;
	}

	function setRewardRateDenom(uint value) external onlyRoot {
		rewardRateDenom = value;
	}

	function setPunishmentRateNum(uint value) external onlyRoot {
		punishmentRateNum = value;
	}

	function setPunishmentRateDenom(uint value) external onlyRoot {
		punishmentRateDenom = value;
	}



	// *** Internal Methods ***
	function _checkBallot(address payable _candidate) private {
		if (totalStake[_candidate] >= upperThreshold || totalStake[_candidate] <= lowerThreshold) {
			bool voted = totalStake[_candidate] >= upperThreshold;

			// Liquidate loan
			if (voted) {
				vaultContract.liquidateLoan(_candidate);
			}

			_giveIncentive(_candidate, voted);
			_resetAllStakesOn(_candidate);

			emit Granted(_candidate);
		}
	}

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

	function _abs(int signed) private pure returns (uint) {
		if (signed < 0) {
			return uint(-signed);
		} else {
			return uint(signed);
		}
	}
}