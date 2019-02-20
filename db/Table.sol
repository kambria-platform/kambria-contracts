pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";

import "./Bytes.sol";
import "./Database.sol";

contract Table {
  using Bytes for *;
    
  address public DB;
  string public NAME;
  bytes4 public DECODE_SELECTOR;
    
  struct Tuple {
    int8 x;
    string y;
    uint256[] z;
  }
    
  Tuple public temp;
  event Find(bool ok, int8 x, string y, uint256[] z);
    
  constructor(address _db, string name) public {
    DB = _db;
    NAME = name;
    DECODE_SELECTOR = bytes4(keccak256("decode(int8,string,uint256[])"));
  }
    
  function decode(int8 x, string y, uint256[] z) public {
    temp = Tuple(x,y,z);
  }
    
  function insert(string key, int8 x, string y, uint256[] z) public {
    Database(DB).set(NAME, key, abi.encode(x, y, z));
  }
  // Exammple input: {"Doge": 8, "Gau gau", [50,30,15,10]}
    
  function find(string key) public {
    bytes memory raw = Database(DB).get(NAME, key);
    bytes memory data = DECODE_SELECTOR.concat(raw);
    bool ok = address(this).call(data);
    emit Find(ok, temp.x, temp.y, temp.z);
  }
  // I am waiting for abi.decode being released in version 0.5.0
  // With this kind of function, we can remove the decode worker and erase
  // enitire the limitations.

  function _find(string key) public view returns (int8, string, uint256[]) {
    bytes memory raw = Database(DB).get(NAME, key);
    // Tuple memory re = Tuple(abi.decode(raw, (int8, string, uint256[])));
    // return re;
  }
}