// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "./IERC20.sol";

contract Treasety is Initializable, ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() initializer public {
        __ERC20_init("Treasety", "CMN");
        __Ownable_init();
        __UUPSUpgradeable_init();
    }

    IERC20 private depositTokenAddress; 

    uint256 private depositId = 0;

    struct DepositStruct {
        address depositor;
        uint256 amount;
        uint256 depositTime;
    }

    struct UserStruct{
        uint256[] depositIds;
        uint256 totalDepositAmount;
        uint256 totalWithdrawAmount;
    }

    mapping (address => UserStruct) public userDetails;
    mapping (uint256 => DepositStruct) public depositDetails;

    event Deposit(address _user, uint256 _depositId, uint256 _amount, uint256 _time);
    event Withdraw(address _user, uint256 _amount, uint256 _time);

    function initializeToken(address _tokenAddress) onlyOwner public returns (bool) {
        require(_tokenAddress != address(0), "This is zero address");
        depositTokenAddress = IERC20(_tokenAddress);
        return true;
    }

    function depositToken(uint256 _amount) public {
        require(depositTokenAddress.balanceOf(address(msg.sender)) > _amount , "Not Enough Tokens available");
       
        DepositStruct memory depositInfo;
        depositInfo = DepositStruct({
            depositor: msg.sender,
            amount: _amount,
            depositTime : block.timestamp
        });
        depositDetails[depositId] = depositInfo;
        userDetails[msg.sender].totalDepositAmount += _amount;
        userDetails[msg.sender].depositIds.push(depositId);
        depositTokenAddress.transferFrom(msg.sender, address(this), _amount);

        emit Deposit(msg.sender, depositId++, _amount, block.timestamp);
    }

    function reward(uint256 _amount, address _recipent) public onlyOwner {
        require(_recipent != address(0), "This is zero address");
        depositTokenAddress.transfer(_recipent, _amount);
        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function adminWithdraw(uint256 _amount) public onlyOwner {
        require(depositTokenAddress.balanceOf(address(this)) > _amount , "Not Enough Tokens available");
        depositTokenAddress.transfer(address(owner()), _amount);

        emit Withdraw(msg.sender, _amount, block.timestamp);
    }

    function _authorizeUpgrade(address newImplementation)
        internal
        onlyOwner
        override
    {}
}
