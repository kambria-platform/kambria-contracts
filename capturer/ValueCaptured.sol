pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";
import "./../helpers/QueryDB.sol";
import "./../helpers/SafeMath.sol";
import "./../token/TokenInterface.sol";
import "./../karma/KarmaDistributionInterface.sol";

contract ValueCaptured is Ownable {
  using SafeMath for uint256;
  using QueryDB for address;

  address public DB;
  uint256 public CURRENT_MILESTONE;
  mapping (uint256 => uint256) milestones; // blockNumber => balances
  mapping (address => mapping (uint256 => bool)) isShared; // address => blockNumber => yes/no
  event SetMilestone(address indexed who, uint256 _duration);
  event Share(address indexed who, uint256 value);

  modifier notShared(uint256 _blockNumber) {
    require(!isShared[msg.sender][_blockNumber]);
    _;
  }

  /**
   * Constructor
   */
  constructor(address _db) public {
    DB = _db;
  }

  function setMilestone(uint256 _duration) public onlyOwner returns (bool) {
    CURRENT_MILESTONE = block.number.add(_duration);
    milestones[CURRENT_MILESTONE] = TokenInterface(DB.getAddress("TOKEN")).balanceOf(address(this));
    emit SetMilestone(msg.sender, _duration);
    return true;
  }

  function share() public notShared(CURRENT_MILESTONE) returns (bool) {
    uint256 valueCaptured = milestones[CURRENT_MILESTONE];
    uint256 numberOfKarma = KarmaDistributionInterface(DB.getAddress("KARMA")).karmaOfAt(msg.sender, CURRENT_MILESTONE);
    uint256 totalKarma = KarmaDistributionInterface(DB.getAddress("KARMA")).totalSupplyAt(CURRENT_MILESTONE);
    uint256 reward = numberOfKarma.mul(valueCaptured).div(totalKarma);

    bool ok = TokenInterface(DB.getAddress("TOKEN")).transfer(msg.sender, reward);
    if (ok) {
      isShared[msg.sender][CURRENT_MILESTONE] = true;
      emit Share(msg.sender, reward);
    }
    return ok;
  }
}