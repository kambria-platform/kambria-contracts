pragma solidity ^0.4.23;

interface SimpleDatabaseInterface {
  function set(string variable, address value) external returns (bool);
  function get(string variable) external view returns (address);
}