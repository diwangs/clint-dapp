pragma solidity >=0.4.25 <0.6.0;

/**
@author Senapati Sang Diwangkara, from Affluent team

@title The Trst Token Contract

TrstToken is a contract for handling Trst transaction and redeeming logic. It also provides
the means to monitor and manipulate the token's total supply and value in the system, that
can only be done by an administrator account (root).

Among the 3 contracts, this contract must be deployed first, because the vault and staking
contract depended on it.

*/
contract TrstToken {
	address payable root;
    address stakeContractAddr;
    address vaultContractAddr;

	uint256 totalSupply;
	uint256 public price; // in Wei/mTrst

	mapping (address => uint256) public balance; // in milliTrst



	constructor() public {
		root = msg.sender;
		balance[root] = 100000; // hard-coded initial balance
		totalSupply = balance[root];

		price = 1000; // 1000 wei == 1 milliTrst
	}



	// *** Modifiers ***
    modifier onlyRoot() {
        require(msg.sender == root, "You're not authorized");
        _;
    }

    modifier onlyClint() {
        require(msg.sender == address(this) ||
			msg.sender == vaultContractAddr ||
			msg.sender == stakeContractAddr ||
			msg.sender == root,
			"You're not authorized");
        _;
    }



	// *** Events ***
	event TokenTx(address indexed _from, address indexed _to, uint _value);
	event PriceChange(uint _price);



    // *** Operation Methods ***
    /**
	* @dev Transfer some tokens from an account to another. Can only be done by another Clint
	* 	contract or root
	* @param _from The address to transfer from
	* @param _to The address to transfer to
	* @param _value The amount to be transferred
	*/
	function transferFrom(address _from, address _to, uint _value) external onlyClint {
		transferFromInternal(_from, _to, _value);
	}

	/**
	* @dev Redeem some token to ETH, will be sent to sender's address
	* @param _value The amount to be redeemed
	*/
    function redeem(uint256 _value) external {
		transferFromInternal(msg.sender, root, _value);
        msg.sender.transfer(_value * price);
    }



    // *** Administrative Methods ***
	/**
	* @dev Create token out of thin air. Can only be called by root.
	* @param _address Destination address
	* @param _value The amount to be minted
	*/
	function mint(address _address, uint256 _value) external onlyRoot {
		balance[_address] += _value;
		totalSupply += _value;

		emit TokenTx(address(0), _address, _value);
	}

	/**
	* @dev Purge token into the void. Can only be called by root.
	* @param _address Victim's address
	* @param _value The amount to be burned
	*/
    function burn(address _address, uint256 _value) external onlyRoot {
		balance[_address] -= _value;
		totalSupply -= _value;

		emit TokenTx(_address, address(0), _value);
	}

	/**
	* @dev Set the Wei/mTrst price. Can only be called by root.
	* @param _price The new price
	*/
	function setPrice(uint _price) external onlyRoot {
		price = _price;

		emit PriceChange(_price);
	}

	/**
	* @dev Fallback function. Used to deposit ETH to the contract
	*/
	function() external payable {}

	/**
	* @dev Withdraw ETH from the contract into root's account. Can only be called by root.
	* @param _value Withdrawal amount
	*/
    function withdraw(uint _value) external onlyRoot {
        root.transfer(_value);
    }

	/**
	* @dev Set the vault contract's address. Can only be called once.
	* @param _address vault contract's address
	*/
	function setVaultContractAddr(address _address) external {
        require(vaultContractAddr == address(0), "Address has been set");
        vaultContractAddr = _address;
    }

	/**
	* @dev Set the stake contract's address. Can only be called once.
	* @param _address stake contract's address
	*/
    function setStakeContractAddr(address _address) external {
        require(stakeContractAddr == address(0), "Address has been set");
        stakeContractAddr = _address;
    }



	// *** Internal Methods ***
    /**
	* @dev Internal method for transfering some tokens from an account to another
	* @param _from The address to transfer from
	* @param _to The address to transfer to
	* @param _value The amount to be transferred
	*/
	function transferFromInternal(address _from, address _to, uint _value) private {
		require(_to != address(0), "Destination address must not be 0"); // Prevent burning?
		require(_value <= balance[_from], "Insufficient balance");

		balance[_from] -= _value;
		balance[_to] += _value;

		emit TokenTx(_from, _to, _value);
	}
}