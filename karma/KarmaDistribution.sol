pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";
import "./../helpers/QueryDB.sol";
import "./../committee/JudgeInterface.sol";
import "./../bounty/BountyInterface.sol";
import "./../bounty/BountyModeratorInterface.sol";
import "./Karma.sol";

contract KarmaDistribution is Karma {
  using SafeMath for uint256;
  using QueryDB for address;

  address public DB;
  mapping(address => bool) public isDistributed;

  event DistributeKarmaToBounty(address caller, address bountyAddress);

  modifier isValidBountyDistribution(address _bountyAddress) {
    require(!isDistributed[_bountyAddress]);
    int256 bountyIndex = BountyModeratorInterface(DB.getAddress("BOUNTY_MODERATOR")).getBountyIndex(_bountyAddress);
    require(bountyIndex >= 0);
    address[] memory winners = JudgeInterface(DB.getAddress("JUDGE")).getChallengeWinners(_bountyAddress);
    require(winners.length > 0);
    _;
  }

  constructor (address _db) public {
    DB = _db;
  }

  function distributeKarmaToBounty(address _bountyAddress) public isValidBountyDistribution(_bountyAddress) returns (bool) {
    uint256 releasedKarma = BountyInterface(_bountyAddress).TOTAL_DEPOSIT();
    address[] memory judges = JudgeInterface(DB.getAddress("JUDGE")).judgeList(_bountyAddress);
    for (uint256 i = 0; i < judges.length; i++) {
      mint(judges[i], releasedKarma.div(judges.length));
    }
    emit DistributeKarmaToBounty(msg.sender, _bountyAddress);
    return true;
  }
}