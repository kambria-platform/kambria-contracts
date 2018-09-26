pragma solidity ^0.4.23;

import "./../token/TokenInterface.sol";
import "./../helpers/QueryDB.sol";

contract Codebase {
  using QueryDB for address;

  string public NAME;
  string public SOURCE;
  address public SUBMITTER;
  address public OWNER;
  address public BOUNTY;
  address public DB;

  event TransferOwnership(address indexed previousOwner, address indexed newOwner);
  event RecievedETH(address indexed who, uint256 value);
  event Withdraw(address indexed who, uint256 value);
  event SendTx(address indexed who, address indexed to,  bytes data, uint256 value, bool ok);

  modifier onlyOwner {
    require(msg.sender == OWNER);
    _;
  }

  modifier onlySubmitter {
    require(msg.sender == SUBMITTER);
    _;
  }

  constructor (
    string _name,
    string _source,
    address _owner,
    address _bounty,
    address _db
  ) public {
    NAME = _name;
    SOURCE = _source;
    SUBMITTER = msg.sender;
    OWNER = _owner;
    BOUNTY = _bounty;
    DB = _db;
  }

  function transferOwnership(address newOwner) public onlyOwner {
    require(newOwner != address(0));
    emit TransferOwnership(OWNER, newOwner);
    OWNER = newOwner;
  }

  function withdraw(uint256 value) public onlyOwner returns (bool) {
    bool ok = TokenInterface(DB.getAddress("TOKEN")).transfer(OWNER, value);
    if (!ok) return false;
    emit Withdraw(OWNER, value);
    return true;    
  }

  function sendTx(address to, bytes data, uint256 value) public onlyOwner returns (bool) {
    bool ok = to.call.value(value)(data);
    emit SendTx(msg.sender, to, data, value, ok);
    return ok;
  }

  function() public payable {
    emit RecievedETH(msg.sender, msg.value);
  }

  function prekill() public onlySubmitter returns (bool) {
    uint256 balance = TokenInterface(DB.getAddress("TOKEN")).balanceOf(address(this));
    bool ok = TokenInterface(DB.getAddress("TOKEN")).transfer(DB.getAddress("VALUE_CAPTURED"), balance);
    if (!ok) return false;
    return true; 
  }
  
  function kill() public onlySubmitter {
    uint256 balance = TokenInterface(DB.getAddress("TOKEN")).balanceOf(address(this));
    require(balance == 0);
    selfdestruct(DB.getAddress("VALUE_CAPTURED"));
  }

}