pragma solidity ^0.4.23;

import "./../simpledb/SimpleDatabaseInterface.sol";

library QueryDB {
  function getAddress(address _db, string _name) internal view returns (address) {
    return SimpleDatabaseInterface(_db).get(_name);
  }
}