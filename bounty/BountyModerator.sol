pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";
import "./../helpers/SafeMath.sol";
import "./../helpers/QueryDB.sol";
import "./../helpers/ListHelpers.sol";
import "./Bounty.sol";
import "./BountyDeployer.sol";

contract BountyModerator is Ownable {
  using SafeMath for uint256;
  using QueryDB for address;
  using ListHelpers for uint256[];

  address public DB;

  struct BountyInfo {
    address owner;
    address token;
    address valuecaptured;
    address judgementProtocol;
    address bounty;
    uint256 start;
    uint256 duration;
    uint256[] percentages;
  }


  uint256 public MAX_PRIZES;
  uint256 public MAX_DURATION_OF_CHALLENGE;
  uint256 public THE_PERCENTAGE_OF_VALUE_CAPTURED;
  uint256 public THE_NUMBER_OF_BOUNTIES;
  mapping(uint256 => BountyInfo) public BountyInfos;

  event NewBounty(address indexed owner, address indexed bounty, uint256 bountyIndex);
  event ChangeMaxPrizes(address indexed owner, uint256 maxpri);
  event ChangeMaxDurationOfChallenge(address indexed owner, uint256 maxdur);
  event ChangeThePercentageOfValueCaptured(address indexed owner, uint256 povc);

  constructor(address _db) public {
    DB = _db;
    MAX_PRIZES = 10;
    MAX_DURATION_OF_CHALLENGE = 3*30*24*60*60; // 90 days
    THE_PERCENTAGE_OF_VALUE_CAPTURED = 5;
  }

  /**
   * Modifier functions
   */
  modifier mustBeValidTimestamps(uint256[4] bountyTimeStamps) {
    uint256 durationOfChallenge;
    for(uint8 count = 0; count < bountyTimeStamps.length; count ++){
      durationOfChallenge = durationOfChallenge.add(bountyTimeStamps[count]);
    }
    require(durationOfChallenge <= MAX_DURATION_OF_CHALLENGE);
    _;
  }


  modifier mustBeValidPercentage(uint256[] _thePercentage) {
    require(_thePercentage[_thePercentage.length - 1] == THE_PERCENTAGE_OF_VALUE_CAPTURED, "the last perceate should be equal the percentage of value captured");
    require(_thePercentage.length > 0 && _thePercentage.length <= MAX_PRIZES, "pecentages length should be less than number of max prize");
    uint256 total = _thePercentage.sum();
    require(total == 100, "total percentages should be equal 100");
    _;
  }

  /** bountyTimeStamps
  * start-> openTime->progressTime->submit hash result -> submit raw result ->close
  * DURATION_OF_CHALLENGE = bountyTimeStamps[0];
  * openTime = bountyTimeStamps[1];
  * progressTime = bountyTimeStamps[2];
  * submitHashResultTime = bountyTimeStamps[3];
  * submitRawResultTime = bountyTimeStamps[4];
  */

  function newBounty(
    address owner,
    uint256[4] bountyTimeStamps,
    uint256[] thePercentage
  ) public
    onlyOwner
    mustBeValidTimestamps(bountyTimeStamps)
    mustBeValidPercentage(thePercentage)
    // returns (bool)
  {
    Bounty bounty = new Bounty(
      DB,
      bountyTimeStamps,
      thePercentage,
      owner
    );

    uint256 durationOfChallenge;
    for(uint8 count = 0; count < bountyTimeStamps.length; count ++){
      durationOfChallenge = durationOfChallenge.add(bountyTimeStamps[count]);
    }
    BountyInfos[THE_NUMBER_OF_BOUNTIES] = BountyInfo(
      owner,
      DB.getAddress("TOKEN"),
      DB.getAddress("VALUE_CAPTURED"),
      DB.getAddress("JUDGEMENT_PROTOCOL"),
      address(bounty),
      block.timestamp,
      durationOfChallenge,
      thePercentage
    );
    THE_NUMBER_OF_BOUNTIES = THE_NUMBER_OF_BOUNTIES.add(1);
    emit NewBounty(msg.sender, bounty, THE_NUMBER_OF_BOUNTIES);
    // return true;
  }

  /**
   * Main functions
   */

  function changeMaxPrizes(uint256 maxpri) public onlyOwner returns (bool) {
    require(maxpri > 0);
    MAX_PRIZES = maxpri;
    emit ChangeMaxPrizes(msg.sender, maxpri);
    return true;
  }

  function changeMaxDurationOfChallenge(uint256 maxdur) public onlyOwner returns (bool) {
    require(maxdur > 0);
    MAX_DURATION_OF_CHALLENGE = maxdur;
    emit ChangeMaxDurationOfChallenge(msg.sender, maxdur);
    return true;
  }

  function changeThePercentageOfValueCaptured(uint256 povc) public onlyOwner returns (bool) {
    require(povc >= 0 && povc <= 100);
    THE_PERCENTAGE_OF_VALUE_CAPTURED = povc;
    emit ChangeThePercentageOfValueCaptured(msg.sender, povc);
    return true;
  }

  function getBountyIndex(address bounty) public view returns (int256) {
    for (uint256 i = 0; i < THE_NUMBER_OF_BOUNTIES; i++) {
      if (bounty == BountyInfos[i].bounty) {
        return int256(i);
      }
    }
    return -1;
  }

  function getBountyPercentages(uint256 bountyIndex) public view returns (uint256[] memory) {
    return BountyInfos[bountyIndex].percentages;
  }
}