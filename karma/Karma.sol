pragma solidity ^0.4.23;

import "./StandardKarma.sol";

contract Karma is StandardKarma {
  string name_;
  string symbol_;
  uint256 decimals_;

  constructor () public {
    name_ = "Karma";
    symbol_ = "K";
    decimals_ = 0;
  }

  function name() public view returns (string) {
    return name_;
  }

  function symbol() public view returns (string) {
    return symbol_;
  }

  function decimals() public view returns (uint256) {
    return decimals_;
  }

}