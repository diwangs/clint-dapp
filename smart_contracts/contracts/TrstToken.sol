pragma solidity >=0.4.25 <0.6.0;

// Using ERC-20 standard

contract TrstToken {
	address _root;

	uint256 _totalSupply;
	uint256 _price;

	int256 _upper_threshold;
	int256 _lower_threshold;
	uint256 _reward;
	uint256 _punishment;
	mapping (address => uint256) private _balances;

	constructor() public {
		_root = msg.sender;
		_balances[_root] = 10000;
		_totalSupply = _balances[_root];

		_price = 2; // 1 Trst == 2 ETH

		_upper_threshold = 100; // How much token untill liquidation?
		_lower_threshold = -100; // How much token untill liquidation?
	}



	// Description Functions
	function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}

	// Token economy control mechanism
	modifier onlyRoot() {
		require(msg.sender == _root, "You're not root");
		_;
	}

	function mint(uint256 _value) public onlyRoot returns (bool) {
		_balances[_root] += _value;
		_totalSupply += _value;
		return true;
	}

	/**
	* @dev Transfer some token from an account to another
	* @param _to The address to transfer to
	* @param _value The amount to be transferred
	* @return a boolean indicating the transfer status
	*/
	function transfer(address _to, uint256 _value) public onlyRoot returns (bool) {
		require(_to != address(0), "Destination address must not be 0"); // Prevent burning?
		require(_value <= balanceOf(msg.sender), "Insufficient balance");

		_balances[msg.sender] -= _value;
		_balances[_to] += _value;

		return true;
	}



	/**
	* ERC-20: Classical transfer mechanism
	*
	*	These following variable, events, and functions are used to transfer
	*	tokens from one account to another. The sender account is assumed to be
	*	the tx sender.
	*/

	// Transfer event
	event Transfer(address indexed _from, address indexed _to, uint256 _value);

	/**
	* @dev Get the token balance of an account
	* @param _owner The address that will be checked.
	* @return The balance of the account
	*/
	function balanceOf(address _owner) public view returns (uint256) {
		return _balances[_owner];
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

	/**
	* @dev A variable that states how much a voter has staked for a given candidate
	* Accessed by _stake[candidate][voter]
	* In ERC-20, this is called `_allowed`
	*/
	mapping (address => mapping (address => int256)) private _stake;
	mapping (address => address[]) private _staker;
	mapping (address => mapping (address => uint)) private _stakeIdx;
	mapping (address => int256) private _totalStake;

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
		require(_candidate != address(0), "Yeet");
		// TODO: clamp value

		// First vote handling
		if (_stake[_candidate][msg.sender] == 0) {
			uint len = _staker[_candidate].push(msg.sender);
			_stakeIdx[_candidate][msg.sender] = len;
		}

		// Vote cancelling
		if (_value == 0) {
			delete _staker[_candidate][_stakeIdx[_candidate][msg.sender]];
			delete _stakeIdx[_candidate][msg.sender];
		}

		// Move balance accordingly
		_totalStake[_candidate] = _totalStake[_candidate] - _stake[_candidate][msg.sender] + _value;
		uint256 absPrevStake = _abs(_stake[_candidate][msg.sender]);
		uint256 absValue = _abs(_value);
		_balances[msg.sender] = _balances[msg.sender] + absPrevStake - absValue;
		_stake[_candidate][msg.sender] = _value;

		// Act if trust threshold exceeded
		if (_totalStake[_candidate] >= _upper_threshold || _totalStake[_candidate] <= _lower_threshold) {
			if (_totalStake[_candidate] >= _upper_threshold) {
				// TODO: actually liquidate
			}

			// TODO: reward and punish

			// reset stake
			_resetStake(_candidate);
		}

		emit Vote(_candidate, msg.sender, _value);
		return true;
	}

	function _resetStake(address _candidate) private {
		delete _totalStake[_candidate];
		for (uint i = 0; i < _staker[_candidate].length; i++) {
			uint256 absStake = _abs(_stake[_candidate][_staker[_candidate][i]]);
			_balances[_staker[_candidate][i]] += absStake;

			delete _stake[_candidate][_staker[_candidate][i]];
			delete _stakeIdx[_candidate][_staker[_candidate][i]];
		}
		delete _staker[_candidate];
	}

	function _abs(int256 signed) private pure returns (uint256) {
		if (signed < 0) {
			return uint256(-signed);
		} else {
			return uint256(signed);
		}
	}


	// Redeem to ETH
}
