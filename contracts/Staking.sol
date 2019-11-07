pragma solidity >=0.4.25 <0.6.0;

import './TrstToken.sol';
import './ClintVault.sol';

contract Staking {
	address _root;
    TrstToken _tokenContract;
    ClintVault _vaultContract;

	int256 _upper_threshold;
	int256 _lower_threshold;
	uint256 _reward_rate;
	uint256 _punishment_rate;

    /**
	* @dev A variable that states how much a voter has staked for a given candidate
	* Accessed by _stake[candidate][voter]
	* In ERC-20, this is called `_allowed`
	*/
	mapping (address => mapping (address => int256)) private _stake;
	mapping (address => address[]) private _stakers;
	mapping (address => mapping (address => uint)) private _stakeIdx;
	mapping (address => int256) private _totalStake;

	constructor(address _tokenContractAddr, address _vaultContractAddr) public {
		_root = msg.sender;

		_upper_threshold = 100000; // How much milliTrst untill liquidation?
		_lower_threshold = -100000; // How much milliTrst untill cancellation?

		_reward_rate = 1; // how much milliTrst should be rewarded for every Trst
		_punishment_rate = 1;

        _tokenContract = TrstToken(_tokenContractAddr);
        _tokenContract.setStakeContractAddr(address(this));
        _vaultContract = ClintVault(_vaultContractAddr);
        _vaultContract.setStakeContractAddr(address(this));
	}

	/**
	* Staking Mechanism
	*
	*	These following variable, events, and functions are used to let
	*	someone (voter) to stake token on somebody else's behalf (candidate)
	*
	* 	Inspired by ERC-20's delegated transfer mechanism, where voter -> spender
	*	and candidate -> owner
	*/

	// Vote event
	event Vote(address indexed _candidate, address indexed _voter, int256 _value);

	/**
	* @dev Get the amount of token someone has staked on a given candidate
	*	In ERC-20, this is called `allowance`
	* @param _candidate The address whose at stake
	* @param _voter The address who staked for that candidate
	* @return the amount of token allowed to be spent
	*/
	function getStake(address _candidate, address _voter) public view returns (int256) {
		return _stake[_candidate][_voter];
	}

	/**
	* @dev Set the stake that a voter will vouch for a candidate
	*	In ERC-20, this is called `allowed` and instead of owner, spender will be set as input
	* 	NOTE: prevent race condition by setting the _value to 0 first before
	* 	setting it to the value we want. This must be done in the frontend.
	* @param _candidate The address whose voter stake to
	* @param _value The amount of stake
	* @return a boolean indicating the set status
	*/
	function setStake(address _candidate, int256 _value) public returns (bool) {
        // TODO: allow revision?
		require(_candidate != address(0), "Yeet");
        require(_vaultContract.getLoanStatusOf(_candidate) == ClintVault.LoanStatus.PROPOSED, "The candidate isn't asking any vote");
        require(_stake[_candidate][msg.sender] == 0, "You've already voted");
		// TODO: clamp value

		uint len = _stakers[_candidate].push(msg.sender);
		_stakeIdx[_candidate][msg.sender] = len;

		// Move balance accordingly
		_totalStake[_candidate] += _value;
        _tokenContract.transferFrom(msg.sender, _root, _abs(_value));
		_stake[_candidate][msg.sender] = _value;

		// Act if trust threshold exceeded
		if (_totalStake[_candidate] >= _upper_threshold || _totalStake[_candidate] <= _lower_threshold) {
			bool voted = _totalStake[_candidate] >= _upper_threshold;

			// Liquidate loan
			if (voted) {
				_vaultContract.liquidateLoan(_candidate);
			}

			// Reward and punish voters
			_giveIncentive(_candidate, voted);

			// reset stake
			_resetStake(_candidate);
		}

		emit Vote(_candidate, msg.sender, _value);
		return true;
	}

	function _giveIncentive(address _candidate, bool voted) private {
		for (uint i = 0; i < _stakers[_candidate].length; i++) {
            address staker = _stakers[_candidate][i];
			bool isYes = _stake[_candidate][staker] > 0;
			uint256 absStake = _abs(_stake[_candidate][staker]);
			if (voted) {
				// reward the yes, punish the no
				if (isYes) {
                    _tokenContract.transferFrom(_root, staker, _reward_rate * (absStake / 1000));
				} else {
                   _tokenContract.transferFrom(staker, _root, _punishment_rate * (absStake / 1000));
				}
			} else {
				// reward the no, punish the yes
				if (isYes) {
                   _tokenContract.transferFrom(staker, _root, _punishment_rate * (absStake / 1000));
				} else {
                    _tokenContract.transferFrom(_root, staker, _reward_rate * (absStake / 1000));
				}
			}
		}
	}

	function _resetStake(address _candidate) private {
		delete _totalStake[_candidate];
		for (uint i = 0; i < _stakers[_candidate].length; i++) {
            address staker = _stakers[_candidate][i];
			uint256 absStake = _abs(_stake[_candidate][staker]);
            _tokenContract.transferFrom(_root, staker, absStake);

			delete _stake[_candidate][_stakers[_candidate][i]];
			delete _stakeIdx[_candidate][_stakers[_candidate][i]];
		}
		delete _stakers[_candidate];
	}

	function _abs(int256 signed) private pure returns (uint256) {
		if (signed < 0) {
			return uint256(-signed);
		} else {
			return uint256(signed);
		}
	}
}