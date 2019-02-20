pragma solidity ^0.4.24;

import "./../helpers/Ownable.sol";
import "./../token/TokenInterface.sol";
import "./../bounty/BountyInterface.sol";
import "./../helpers/ListHelpers.sol";
import "./../helpers/StringHelpers.sol";
import "./../helpers/MathHelpers.sol";
import "./../ballot/BallotLib.sol";
import "./JudgeLib.sol";
import "./JudgementProtocol.sol";
import "./../helpers/QueryDB.sol";

contract JudgeCommittee {
  using ListHelpers for address[];
  using ListHelpers for uint256[];
  using StringHelpers for uint256;
  using SafeMath for uint256;
  using StringHelpers for string;
  using BallotLib for BallotLib.Ballot;
  using JudgeLib for JudgeLib.Judge;
  using QueryDB for address;

  address public tokenAddress;
  // this contract does not inherit Ownable class 
  // because it's risky to allow transfering owner
  address public owner;
  JudgementProtocol public judgementProtocol;
  uint256[] public scores;
  address[] public judgeAddresses;
  uint256 public totalStakedAmount;
  uint256 public backerJudgesStrength;
  uint256 public developerJudgesStrength;
  uint256 public numberBallotsVotedForHavingWinnersFromDeveloperJudges;
  uint256 public numberOfValidBallotsFromDeveloperJudges;
  address public valueCaptured;
  uint256 public currentNumOfValidBallotsHaveNotBeenWithdrawed;
  
  BountyInterface public bountyInterface;

  mapping (address => JudgeLib.Judge) public judges;
  mapping (address => address) choosersToJudges;
  mapping (address => BallotLib.Ballot) public ballots;
  mapping (uint256 => uint256[]) public weightsOfScoresFromBackerJudges;
  mapping (uint256 => uint256[]) public weightsOfScoresFromDeveloperJudges;

  event ChooseDeveloperJudge(address indexed teamOwner, address indexed candidate);
  event ChooseBackerJudge(address indexed teamOwner, address indexed candidate);
  event SubmitHashResult(address indexed judgeAddress, bytes32 hashResult);
  event SubmitRawResult(address indexed judgeAddress, uint256[] scoresForTeams, uint256 randomNumber);
  event SubmitHavingWinnersDecision(address indexed judgeAddress, bool hasWinners);
  event Withdraw(address indexed who, uint256 value);

  constructor(address DB, address bountyAddress) public {
    // to ensure the owner of this contract is a bounty
    // TODO: check sceranio 2: remove _bountyAddress in the input 
    // then change bountyInterface = BountyInterface(msg.sender); 
    require (bountyAddress == msg.sender);
    tokenAddress = DB.getAddress("TOKEN");
    valueCaptured = DB.getAddress("VALUE_CAPTURED");
    address judgementProtocolAddress = DB.getAddress("JUDGEMENT_PROTOCOL");
    owner = msg.sender;
    judgementProtocol = JudgementProtocol(judgementProtocolAddress);
    bountyInterface = BountyInterface(bountyAddress);
  }

  function chooseDeveloperJudge(address candidate) public onlyRegisteredTeam onlyInProgressState candidateIsNotAJudge(candidate){
    // ensure no body can choose judges twice.
    require(choosersToJudges[msg.sender] == address(0));
    transferTokenFromCandidateToJudgeCommittee(candidate);
    choosersToJudges[msg.sender] = candidate;
    judges[candidate].judgeType = JudgeLib.JudgeType.DeveloperJudge;
    judgeAddresses.push(candidate);
    emit ChooseDeveloperJudge(msg.sender, candidate);
  }

  function chooseBackerJudge(address candidate) public onlyBacker onlyInProgressState candidateIsNotAJudge(candidate) {
    // ensure no body can choose judges twice.
    require(choosersToJudges[msg.sender] == address(0));
    transferTokenFromCandidateToJudgeCommittee(candidate);
    choosersToJudges[msg.sender] = candidate;
    judges[candidate].judgeType = JudgeLib.JudgeType.BackerJudge;
    judgeAddresses.push(candidate);
    emit ChooseBackerJudge(msg.sender, candidate);
  }

  function transferTokenFromCandidateToJudgeCommittee(address candidate) private {
    uint256 approvedAmount = TokenInterface(tokenAddress).allowance(candidate, this);
    require(approvedAmount > 0);
    TokenInterface(tokenAddress).transferFrom(candidate, this, approvedAmount);
    judges[candidate].depositedAmount = approvedAmount;
    totalStakedAmount = totalStakedAmount.add(approvedAmount);
  }

  function submitHashResult(bytes32 hashResult) public onlyJudge onlyInPeriodOfSubmmitingHashReuslt {
    BallotLib.Ballot storage ballot = ballots[msg.sender];
    ballot.hashResult = hashResult;
    ballot.weight = judges[msg.sender].depositedAmount;
    if(isBackerJudge(msg.sender)) {
      ballot.ballotType = BallotLib.BallotType.FromBackerJudge;
    } else {
      ballot.ballotType = BallotLib.BallotType.FromDeveloperJudge;
    }
    emit SubmitHashResult(msg.sender, hashResult);
  }

  function submitRawResult(
    uint256[] memory scoresForTeams,
    uint256 randomNumber,
    bool hasWinners
  ) public onlyJudge onlyInPeriodOfSubmmitingRawReuslt {
    BallotLib.Ballot storage ballot = ballots[msg.sender];
    // this require ensures judges can only submit raw result once.
    // if we allow judges submit multiple times
    // we must revert consequence from the last submit.
    require(ballot.isUnChecked());
    ballot.scoresForTeams = scoresForTeams;
    ballot.randomNumber = randomNumber;
    ballot.hasWinners = hasWinners;
    uint16 numberOfTeams = bountyInterface.numberOfTeams();
    ballot.checkBallot(numberOfTeams);
    if(ballot.isValid()) {
      if(isBackerJudge(msg.sender)) {
        updateWeightsFromBackerJudges(scoresForTeams, numberOfTeams, ballot.weight);
      } else {
        updateWeightsFromDeveloperJudges(scoresForTeams, numberOfTeams, ballot.weight);
        numberOfValidBallotsFromDeveloperJudges = numberOfValidBallotsFromDeveloperJudges.add(1);
        if(hasWinners) numberBallotsVotedForHavingWinnersFromDeveloperJudges = numberBallotsVotedForHavingWinnersFromDeveloperJudges.add(1);
      }
      currentNumOfValidBallotsHaveNotBeenWithdrawed = currentNumOfValidBallotsHaveNotBeenWithdrawed.add(1);
    }
    emit SubmitRawResult(msg.sender, scoresForTeams, randomNumber);
  }

  function updateWeightsFromBackerJudges(
    uint256[] memory scoresForTeams,
    uint16 numberOfTeams,
    uint256 weight
  ) private {
    uint16 maxScore = numberOfTeams;
    // weightsOfScoresForTeams[0] and weightsOfScoresForTeams[numberOfTeam + 1] must always = 0
    for(uint16 score = 1; score <= maxScore; score ++) {
      uint256 teamIndex = scoresForTeams[score - 1];
      // generate new weights of scores array for each team
      // score array's length = numberOfTeams + 2 
      // because we need to pad zero at the beginning and the end of array
      if(weightsOfScoresFromBackerJudges[teamIndex].length == 0){
        weightsOfScoresFromBackerJudges[teamIndex] = new uint256[](numberOfTeams + 2);
      }
      weightsOfScoresFromBackerJudges[teamIndex][score] = weightsOfScoresFromBackerJudges[teamIndex][score].add(weight);
    }
    backerJudgesStrength = backerJudgesStrength.add(weight);
  }

  function updateWeightsFromDeveloperJudges(
    uint256[] memory scoresForTeams,
    uint16 numberOfTeams,
    uint256 weight
  ) private {
    uint16 maxScore = numberOfTeams;
    // weightsOfScoresForTeams[0] and weightsOfScoresForTeams[numberOfTeam + 1] must always = 0
    for(uint16 score = 1; score <= maxScore; score ++) {
      // generate new weights of scores array for each team
      // score array's length = numberOfTeams + 2 
      // because we need to pad zero at the beginning and the end of array
      uint256 teamIndex = scoresForTeams[score - 1];
      if(weightsOfScoresFromDeveloperJudges[teamIndex].length == 0){
        weightsOfScoresFromDeveloperJudges[teamIndex] = new uint256[](numberOfTeams + 2);
      }
      weightsOfScoresFromDeveloperJudges[teamIndex][score] = weightsOfScoresFromDeveloperJudges[teamIndex][score].add(weight);
    }
    developerJudgesStrength = developerJudgesStrength.add(weight);
  }

  function judge() external onlyOwner returns(uint256[]) {
    uint16 numberOfTeams = bountyInterface.numberOfTeams();
    calculateFinalScoreForEachTeam(numberOfTeams);
    bool hasWinners = (numberBallotsVotedForHavingWinnersFromDeveloperJudges * 2 >= numberOfValidBallotsFromDeveloperJudges);
    if(scores.length == 0 || !hasWinners){
      return new uint256[](0);
    }
    uint16 numberOfPrizes = bountyInterface.numberOfPrizes();
    return scores.getIndexesOfMaxValues(numberOfPrizes);
  }

  function calculateFinalScoreForEachTeam(uint16 numberOfTeams) private returns(bool){
    scores = new uint256[](0);
    if(developerJudgesStrength == 0 && backerJudgesStrength == 0) return false;
    uint16 maxScore = numberOfTeams;
    for(uint16 teamIndex = 0; teamIndex < numberOfTeams; teamIndex ++) {
      uint256[] memory weightsOfScores = new uint256[](numberOfTeams + 2);
      // weightsOfScores[0] and weightsOfScores[numberOfTeam + 1] must always = 0
      if(developerJudgesStrength == 0) {
        weightsOfScores = weightsOfScoresFromBackerJudges[teamIndex];
      } else if(backerJudgesStrength == 0){
        weightsOfScores = weightsOfScoresFromDeveloperJudges[teamIndex];
      } 
      else {
      // for from 1 because weightsOfScores[0] and weightsOfScores[numberOfTeam + 1] must always = 0
        for(uint16 score = 1; score <= maxScore; score++) {
          // to balance the strength of two judges
          weightsOfScores[score] = weightsOfScores[score]
          .add(weightsOfScoresFromDeveloperJudges[teamIndex][score].mul(backerJudgesStrength))
          .add(weightsOfScoresFromBackerJudges[teamIndex][score].mul(developerJudgesStrength));
        }
      }
      uint256 finalScore = judgementProtocol.calculateFinalScore(weightsOfScores);
      scores.push(finalScore);
    }
    return true;
  }

  function withdraw() public onlyInClosedState returns (bool) {
    require(isJudged());
    BallotLib.Ballot storage ballot = ballots[msg.sender];
    require(ballot.isValid());
    uint256 amount = judges[msg.sender].depositedAmount;
    require(amount > 0);
    uint256 remainBalance = TokenInterface(tokenAddress).balanceOf(this);
    require(remainBalance >= amount);
    // when the last judge withdraws he has to transfer remain balance to valueCaptured address
    if(currentNumOfValidBallotsHaveNotBeenWithdrawed == 1) {
      TokenInterface(tokenAddress).transfer(valueCaptured, remainBalance.sub(amount));
      emit Withdraw(valueCaptured, remainBalance.sub(amount));
    }
    judges[msg.sender].depositedAmount = 0;
    currentNumOfValidBallotsHaveNotBeenWithdrawed = currentNumOfValidBallotsHaveNotBeenWithdrawed.sub(1);
    emit Withdraw(msg.sender, amount);
    return TokenInterface(tokenAddress).transfer(msg.sender, amount);
  }

  modifier onlyJudge () {
    require(isDeveloperJudge(msg.sender) || isBackerJudge(msg.sender));
    _;
  }

  modifier onlyBacker() {
    require(bountyInterface.isBacker(msg.sender));
    _;
  }

  modifier onlyRegisteredTeam() {
    require(bountyInterface.isInParticipatedTeams(msg.sender));
    _;
  }

  modifier candidateIsNotAJudge(address candidate) {
    require(!isDeveloperJudge(candidate) && !isBackerJudge(candidate));
    _;
  }

  modifier onlyDeveloperJudge() {
    require(isDeveloperJudge(msg.sender));
    _;
  }

  modifier onlyInPeriodOfDepositing() {
    require(bountyInterface.isInPeriodOfDepositing());
    _;
  }

  modifier onlyInProgressState() {
    require(bountyInterface.isBountyInProgressState());
    _;
  }

  modifier onlyInPeriodOfSubmmitingHashReuslt() {
    require(bountyInterface.isBountyInSubmitHashResultState());
    _;
  }
  modifier onlyInPeriodOfSubmmitingRawReuslt() {
    require(bountyInterface.isBountyInSubmitRawResultState());
    _;
  }

  modifier onlyInClosedState() {
    require(bountyInterface.isBountyInClosedState());
    _;
  }

  modifier onlyOwner() {
    require(msg.sender == owner);
    _;
  }
  
  function isDeveloperJudge(address judgeAddress) public view returns(bool) {
    return judges[judgeAddress].isDeveloperJudge();
  }
  
  function isBackerJudge(address candidate) public view returns(bool) {
    return judges[candidate].isBackerJudge();
  }

  function getScores() public view returns(uint256[]) {
    return scores;
  }

  function getJudgeList() public view returns(address[]) {
    return judgeAddresses;
  }

  function getWeightsOfScoresForTeamFromDeveloperJudges(uint256 teamIndex) public view returns (uint256[] memory) {
    return weightsOfScoresFromDeveloperJudges[teamIndex];
  }

  function getWeightsOfScoresForTeamFromBackerJudges(uint256 teamIndex) public view returns (uint256[] memory) {
    return weightsOfScoresFromBackerJudges[teamIndex];
  }

  function getTeamsScoreFromJudge(address judgeAddress) public view returns(uint256[] memory) {
    return ballots[judgeAddress].scoresForTeams;
  }
  
  function isJudged() public view returns(bool){
    return bountyInterface.isJudged();
  }

  function numberOfTeams() public view returns(uint16) {
    return bountyInterface.numberOfTeams();
  }
}