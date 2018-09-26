pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";
import "./../helpers/SafeMath.sol";
import "./../helpers/QueryDB.sol";
import "./Bounty.sol";

contract BountyModerator is Ownable {
  using SafeMath for uint256;
  using QueryDB for address;

  address public DB;

  struct BountyInfo {
    address owner;
    address token;
    address judge;
    address valuecaptured;
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

  event NewBounty(address indexed owner, address indexed bounty);
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
  modifier isValidDuration(uint256 durationOfChallenge) {
    require(durationOfChallenge > 0 && durationOfChallenge <= MAX_DURATION_OF_CHALLENGE);
    _;
  }

  modifier isValidNumberOfPrizes(uint256[] _thePercentage) {
    require(_thePercentage.length > 0 && _thePercentage.length <= MAX_PRIZES);
    _;
  }

  modifier hasPecentageOfValueCaptured(uint256[] _thePercentage) {
    require(_thePercentage[_thePercentage.length - 1] == THE_PERCENTAGE_OF_VALUE_CAPTURED);
    _;
  }

  modifier isValidPercentage(uint256[] _thePercentage) {
    uint256 total = 0;
    for (uint256 i = 0; i < _thePercentage.length; i++) {
      total = total.add(_thePercentage[i]);
    }
    require(total == 100);
    _;
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

  function getBountyPercentages(uint256 bountyIndex, uint256 prize) public view returns (uint256) {
    return BountyInfos[bountyIndex].percentages[prize];
  }

  function newBounty(
    address owner,
    uint256 durationOfChallenge,
    uint256[] thePercentage
  ) public
    onlyOwner
    isValidDuration(durationOfChallenge)
    isValidNumberOfPrizes(thePercentage)
    hasPecentageOfValueCaptured(thePercentage)
    isValidPercentage(thePercentage)
    returns (bool)
  {
    address TOKEN = DB.getAddress("TOKEN");
    address JUDGE = DB.getAddress("JUDGE");
    address VALUE_CAPTURED = DB.getAddress("VALUE_CAPTURED");
    Bounty bounty = new Bounty(TOKEN, JUDGE, VALUE_CAPTURED, durationOfChallenge, thePercentage);
    BountyInfos[THE_NUMBER_OF_BOUNTIES] = BountyInfo(
      owner,
      TOKEN,
      JUDGE,
      VALUE_CAPTURED,
      bounty,
      block.timestamp,
      durationOfChallenge,
      thePercentage
    );
    THE_NUMBER_OF_BOUNTIES = THE_NUMBER_OF_BOUNTIES.add(1);
    emit NewBounty(msg.sender, bounty);
    return true;
  }
}