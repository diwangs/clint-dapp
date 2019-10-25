pragma solidity >=0.4.25 <0.6.0;

contract TrstToken {
	address _root;
    address _stakeContractAddr;

	uint256 _totalSupply;
	uint256 _price;

	mapping (address => uint256) private _balances; // in milliTrst

	constructor() public {
		_root = msg.sender;
		_balances[_root] = 100000;
		_totalSupply = _balances[_root];

		_price = 1000; // 1000 wei == 1 milliTrst
	}


    modifier onlyRoot() {
        require(msg.sender == _root, "You're not root");
        _;
    }

    modifier onlyStakeContract() {
        require(msg.sender == _stakeContractAddr, "You're not a stake contract");
        _;
    }


    function balanceOf(address _owner) public view returns (uint256) {
		return _balances[_owner];
	}

    function totalSupply() public view returns (uint256) {
		return _totalSupply;
	}


    /**
	* @dev Transfer some token from an account to another
	* @param _to The address to transfer to
	* @param _value The amount to be transferred
	* @return a boolean indicating the transfer status
	*/
	function transferFrom(address _from, address _to, uint256 _value) public onlyStakeContract returns (bool) {
		require(_to != address(0), "Destination address must not be 0"); // Prevent burning?
		require(_value <= balanceOf(_from), "Insufficient balance");

		_balances[_from] -= _value;
		_balances[_to] += _value;

		return true;
	}

    function redeem(uint256 _value) public returns (bool) {
        // check if sufficient
        // send ETH to msg.sender
        return true;
    }


    // Administrative
	function mint(address _address, uint256 _value) public onlyRoot returns (bool) {
		_balances[_address] += _value;
		_totalSupply += _value;
		return true;
	}

    function burn(address _address, uint256 _value) public onlyRoot returns (bool) {
		_balances[_address] -= _value;
		_totalSupply -= _value;
		return true;
	}

    // TODO: Authorize this
    function setStakeContractAddr(address _address) public {
        _stakeContractAddr = _address;
    }
}