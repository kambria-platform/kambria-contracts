pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";

contract SimpleDatabase is Ownable {

  mapping(bytes32 => address) public storedAddress;
  event Set(address indexed submitter, string variable, address value);

  constructor() public { }

  function set(string variable, address value) public onlyOwner returns (bool) {
    bytes32 key = keccak256(abi.encode(variable));
    storedAddress[key] = value;
    emit Set(msg.sender, variable, value);
    return true;
  }

  function get(string variable) public view returns (address) {
    bytes32 key = keccak256(abi.encode(variable));
    require(storedAddress[key] != address(0), "Haha");
    return storedAddress[key];
  }

}