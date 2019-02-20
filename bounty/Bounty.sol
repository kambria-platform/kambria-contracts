pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";
import "./../committee/JudgeInterface.sol";
import "./../token/TokenInterface.sol";
import "./../committee/JudgeCommittee.sol";
import "./../committee/JudgeCommitteeInterface.sol";
import "./../helpers/ListHelpers.sol";
import "../committee/JudgeCommitteeDeployer.sol";
import "./../helpers/QueryDB.sol";

contract Bounty {
  using SafeMath for uint256;
  using ListHelpers for address[];
  using ListHelpers for uint256[];
  using QueryDB for address;
  
  address public MODERATOR;
  address public TOKEN;
  address public VALUE_CAPTURED;
  address public JUDGE_COMMITTEE;
  address public DB;
  address public bountyOwner;
  uint256 public START;
  uint256 public THE_CURRENT_NUMBER_OF_SPONSORS;
  uint256 public TOTAL_DEPOSIT;
  uint256 public progressTime;
  uint256 public startTimeForSubmitingHashResult;
  uint256 public startTimeForSubmitingRawResult;
  uint256 public closedTime;
  uint16 public numberOfTeams;
  uint256[] public THE_CURRENT_PERCENTAGES;
  address[] public teamAddresses;
  bool public isConfirmed;
  bool public isJudged;
  uint256[] winnersIndexes;

  struct Team {
    uint256 teamId;
    string name;
    uint16 teamIndex;
  }

  mapping(address => uint) public sponsors;
  mapping(address => Team) public teams;

  event ConfirmBounty(address indexed bountyOwner, uint256 time);
  event RegisterTeam(address indexed teamOwner, string name, uint256 id, uint256 index);
  event Deposit(address indexed who, uint256 value);
  event JudgeBounty(address indexed who);
  event Withdraw(address indexed who, uint256 value);

    // bounty timestamps: start-> openTime->progressTime->submitHashResultTime -> submitRawResultTime ->close
  constructor (
    address db,
    uint256[4] bountyTimeStamps,
    uint256[] thePercentages,
    address owner
  ) public {
    MODERATOR = msg.sender;
    DB = db;
    TOKEN = DB.getAddress("TOKEN");
    VALUE_CAPTURED = DB.getAddress("VALUE_CAPTURED");
    START = block.timestamp;
    THE_CURRENT_PERCENTAGES = thePercentages;
    progressTime = START.add(bountyTimeStamps[0]);
    startTimeForSubmitingHashResult = progressTime.add(bountyTimeStamps[1]);
    startTimeForSubmitingRawResult = startTimeForSubmitingHashResult.add(bountyTimeStamps[2]);
    closedTime = startTimeForSubmitingRawResult.add(bountyTimeStamps[3]);
    bountyOwner = owner;
  }

  function confirmBounty() public onlyBountyOwner returns(bool) {
    require(isBountyInOpenState());
    sponsorToBountyFrom(msg.sender);
    isConfirmed = true;
    JUDGE_COMMITTEE = JudgeCommitteeDeployer.deployJudgeCommittee(DB, this);
    emit ConfirmBounty(msg.sender, block.timestamp);
    return true;
  }

  function deposit() public returns (bool) {
    return depositFrom(msg.sender);
  }
  
  function depositFrom(address sponsor) public onlyInPeriodOfDepositing returns (bool) {
    return sponsorToBountyFrom(sponsor);
  }

  function sponsorToBountyFrom(address sponsor) private returns (bool) {
    // Transfer token and record sponsor
    uint256 value = TokenInterface(TOKEN).allowance(sponsor, this);
    require(value > 0);
    TokenInterface(TOKEN).transferFrom(sponsor, this, value);
    TOTAL_DEPOSIT = TOTAL_DEPOSIT.add(value);
    emit Deposit(sponsor, value);
    if (sponsors[sponsor] > 0){
      // Re-deposit
      sponsors[sponsor] = sponsors[sponsor].add(value);
    } else {
      // Newly deposit
      THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.add(1);
      sponsors[sponsor] = value;
    }
    return true;
  }

  function registerTeam(uint256 teamId, string name, uint16 teamIndex) public onlyInOpenOrConfirmedState {
    require(!isInParticipatedTeams(msg.sender));
    require(msg.sender != bountyOwner);
    Team memory team = Team(teamId, name, teamIndex);
    teams[msg.sender] = team;
    teamAddresses.push(msg.sender);
    numberOfTeams++;
    emit RegisterTeam(msg.sender, name, teamId, teamIndex);
  }

  function judgeBounty() public onlyInClosedState {
    JudgeCommitteeInterface judgeCommittee = JudgeCommitteeInterface(JUDGE_COMMITTEE);
    winnersIndexes = judgeCommittee.judge();
    isJudged = true;
    emit JudgeBounty(msg.sender);
  }

  function withdraw() public onlyInClosedState returns (bool) {
    require(isJudged);
    uint256 remainer = TokenInterface(TOKEN).balanceOf(address(this));
    // Cannot withdraw if the remainer is zero
    require(remainer > 0);
    // Sponsors withdraw
    if (winnersIndexes.length == 0) {
      require(THE_CURRENT_NUMBER_OF_SPONSORS > 0);
      require(sponsors[msg.sender] > 0);
      if (THE_CURRENT_NUMBER_OF_SPONSORS > 1) {
        sponsors[msg.sender] = 0;
        THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.sub(1);
        TokenInterface(TOKEN).transfer(msg.sender, sponsors[msg.sender]);
        emit Withdraw(msg.sender, sponsors[msg.sender]);
      } else {
        TokenInterface(TOKEN).transfer(VALUE_CAPTURED, remainer.sub(sponsors[msg.sender])); // Tranfer to Value-Captured
        emit Withdraw(VALUE_CAPTURED, remainer.sub(sponsors[msg.sender]));
        sponsors[msg.sender] = 0;
        THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.sub(1);
        TokenInterface(TOKEN).transfer(msg.sender, sponsors[msg.sender]);
        emit Withdraw(msg.sender, sponsors[msg.sender]);
      }
      return true;
    }

    // Winners withdraw
    int256 index = teamAddresses.includes(msg.sender);
    if (index >= 0 && index < int256(THE_CURRENT_PERCENTAGES.length.sub(1))) {
      uint256 prize = uint256(index);
      uint256 reward = remainer.mul(THE_CURRENT_PERCENTAGES[prize]).div(THE_CURRENT_PERCENTAGES.sum());
      THE_CURRENT_PERCENTAGES[prize] = 0;
      TokenInterface(TOKEN).transfer(msg.sender, reward);
      emit Withdraw(msg.sender, reward);
      if (THE_CURRENT_PERCENTAGES.sum(0, THE_CURRENT_PERCENTAGES.length.sub(1)) == 0) {
        TokenInterface(TOKEN).transfer(VALUE_CAPTURED, remainer.sub(reward));
        emit Withdraw(VALUE_CAPTURED, remainer.sub(reward));
      }
      return true;
    }
    revert();
  }

  function isInParticipatedTeams(address teamAddress) public view returns(bool){
    return teamAddresses.includes(teamAddress) >= 0;
  }

  function isBacker(address backerAddress) public view returns(bool){
    return sponsors[backerAddress] > 0;
  }

  function getWinnersIndexes() public view returns(uint256[]) {
    return winnersIndexes;
  }

  function getCurrentPercentages() public view returns(uint256[]) {
    return THE_CURRENT_PERCENTAGES;
  }

  function numberOfPrizes() public view returns(uint16) {
    return uint16(THE_CURRENT_PERCENTAGES.length - 1);
  }

  function getTeamAddresses() public view returns(address[]) {
    return teamAddresses;
  }

  modifier onlyInPeriodOfDepositing() {
    require(isInPeriodOfDepositing());
    _;
  }

  modifier onlyInOpenOrConfirmedState() {
    require(isBountyInOpenState() || isBountyInConfirmedState());
    _;
  }

  modifier onlyInClosedState() {
    require(isBountyInClosedState());
    _;
  }

  modifier onlyBountyOwner() {
    require(msg.sender == bountyOwner);
    _;
  }

  function isInOpenTime() public view returns(bool) {
    return block.timestamp >= START && block.timestamp < progressTime;
  }

  function isBountyInOpenState() public view returns(bool) {
    return(isInOpenTime() && !isConfirmed);
  }

  function isBountyInConfirmedState() public view returns(bool) {
    return(isConfirmed && isInOpenTime());
  }
  
  function isBountyInCanceledState() public view returns(bool) {
    return (!isInOpenTime() && !isConfirmed);
  }

  function isInPeriodOfDepositing() public view returns(bool) {
    return isBountyInConfirmedState() || isBountyInProgressState();
  }

  function isBountyInProgressState() public view returns(bool) {
    return isConfirmed && block.timestamp >= progressTime && block.timestamp < startTimeForSubmitingHashResult;
  }

  function isBountyInSubmitHashResultState() public view returns(bool) {
    return isConfirmed && block.timestamp >= startTimeForSubmitingHashResult && block.timestamp < startTimeForSubmitingRawResult;
  }

  function isBountyInSubmitRawResultState() public view returns(bool) {
    return isConfirmed && block.timestamp >= startTimeForSubmitingRawResult && block.timestamp < closedTime;
  }

  function isBountyInClosedState() public view returns(bool) {
    return isConfirmed && block.timestamp >= closedTime;
  }
}