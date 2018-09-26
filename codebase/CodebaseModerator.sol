pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";
import "./Codebase.sol";

contract CodebaseModerator is Ownable {

  address public DB;
  mapping(bytes32 => address) public CodebaseAddresses;

  event NewCodebase(address indexed submitter, address indexed owner, address indexed codebase);
  event RemoveCodebase(address indexed submitter, address indexed codebase, bool ok);

  modifier isNotUsedName(string _name) {
    bytes32 key = keccak256(abi.encode(_name));
    require(CodebaseAddresses[key] == address(0));
    _;
  }

  modifier isUsedName(string _name) {
    bytes32 key = keccak256(abi.encode(_name));
    require(CodebaseAddresses[key] != address(0));
    _;
  }

  constructor (address _db) public {
    DB = _db;
  }

  function findCodebaseAddressByName(string _name) public view returns (address) {
    bytes32 key = keccak256(abi.encode(_name));
    return CodebaseAddresses[key];
  }

  function removeCodebase(string _name) public onlyOwner isUsedName(_name) {
    bytes32 key = keccak256(abi.encode(_name));
    address codebase = CodebaseAddresses[key];
    bool ok = Codebase(codebase).prekill();
    if(ok) {
      Codebase(codebase).kill();
      CodebaseAddresses[key] = address(0);
    }
    emit RemoveCodebase(msg.sender, codebase, ok);
  }

  function newCodebase(
    string _name,
    string _source,
    address _owner,
    address _bounty
  ) public onlyOwner isNotUsedName(_name) {
    bytes32 key = keccak256(abi.encode(_name));
    Codebase codebase = new Codebase(_name, _source, _owner, _bounty, DB);
    CodebaseAddresses[key] = codebase;
    emit NewCodebase(msg.sender, _owner, codebase);
  }
}