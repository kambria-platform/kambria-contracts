pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";

contract Database {
  // Roles
  enum Role {reader, writer, owner}
  // TableNameHash => KeyHash => Value
  mapping(bytes32 => mapping(bytes32 => bytes)) public db;
  // MemberAddress => TableNameHash => Role
  mapping(address => mapping(bytes32 => Role)) public privilege;
  // TableNameHash => Boolean
  mapping(bytes32 => bool) public tableExisted;
  
  // Events
  event Register(address indexed owner, string table);
  event Grant(address indexed owner, string table, address indexed member, Role role);
  event Revoke(address indexed owner, string table, address indexed member);
  event Write(address indexed member, string table);
  
  // Modifiers
  modifier isOwner(string tableName) {
    require(privilege[msg.sender][encode(tableName)] >= Role.owner);
    _;
  }
  modifier isWriter(string tableName) {
    require(privilege[msg.sender][encode(tableName)] >= Role.writer);
    _;
  }
  modifier isReader(string tableName) {
    require(privilege[msg.sender][encode(tableName)] >= Role.reader);
    _;
  }
  modifier tableMustExist(string tableName) {
    require(tableExisted[encode(tableName)]);
    _;
  }
  modifier tableMustNotExist(string tableName) {
    require(!tableExisted[encode(tableName)]);
    _;
  }

  // Utility functions
  function encode(string _input) public pure returns (bytes32) {
    return keccak256(bytes(_input));
  }
  
  // Role management functions
  // Register new table
  function register(string tableName) public tableMustNotExist(tableName) returns (bool) {
    privilege[msg.sender][encode(tableName)] = Role.owner;
    emit Register(msg.sender, tableName);
    return true;
  }
  // Grant privilege to another address
  function grant(string tableName, address member, Role role) public isOwner(tableName) returns (bool) {
    require(msg.sender != member);
    privilege[member][encode(tableName)] = role;
    emit Grant(msg.sender, tableName, member, role);
    return true;
  }
  // Revoke privilege to another address
  function revoke(string tableName, address member) public isOwner(tableName) returns (bool) {
    require(msg.sender != member);
    privilege[member][encode(tableName)] = Role.reader;
    emit Revoke(msg.sender, tableName, member);
    return true;
  }
  
  // Document management functions
  function set(string tableName, string key, bytes data) public isWriter(tableName) returns (bool) {
    db[encode(tableName)][encode(key)] = data;
    emit Write(msg.sender, tableName);
    return true;
  }
    
  function get(string tableName, string key) public view returns (bytes) {
    return db[encode(tableName)][encode(key)];
  }
}