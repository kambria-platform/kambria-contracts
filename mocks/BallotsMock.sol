pragma solidity ^0.4.24;

import "./../helpers/ListHelpers.sol";
import "./../helpers/StringHelpers.sol";
import "./../helpers/MathHelpers.sol";

contract BallotsMock {
  using ListHelpers for uint256[];
  using StringHelpers for uint256;
  using StringHelpers for string;

  mapping(address => Ballot) public ballots;
  mapping(uint256 => uint256[]) public teamWeights;
  uint256[] public scores;
  uint256[] public winners;
  address[] public judgeAddresses;


  enum BallotType {
    FromNoOne,
    FromDeveloperJudge,
    FromBackerJudge
  }

  struct Ballot {
    BallotType ballotType;
    uint256 weight;
    bytes32 hashResult;
    uint256[] winnersIndexes;
    uint256 randomNumber;
    bool hasWinners;
    bool isValid;
  }

  function checkBallot(
    bytes32 hashResult, 
    uint256[] memory winnersIndexes, 
    uint256 randomNumber, 
    uint16 numberOfTeams
  ) public pure returns(bool) {
    if(winnersIndexes.length == 0 && randomNumber == 0) return false;
    string memory stringToVerify = winnersIndexes.toString().concatenate(randomNumber.toString());
    if(keccak256(bytes(stringToVerify)) != hashResult) return false;
    uint256[] memory sortedIndexes = winnersIndexes.sort();
    if(!sortedIndexes.isStrictlyIncreasing()) return false;
    if(sortedIndexes[sortedIndexes.length - 1] >= numberOfTeams) return false;
    return true;
  }

  function addBallot(
    address judgeAddress, 
    uint256[] winnersIndexes, 
    uint256 randomNumber, 
    bytes32 hashResult, 
    BallotType ballotType, 
    uint256 weight,
    bool hasWinners
  ) public {
    ballots[judgeAddress].hashResult = hashResult;
    ballots[judgeAddress].winnersIndexes = winnersIndexes;
    ballots[judgeAddress].randomNumber = randomNumber;
    ballots[judgeAddress].ballotType = ballotType;
    ballots[judgeAddress].weight = weight;
    ballots[judgeAddress].hasWinners = hasWinners;
    judgeAddresses.push(judgeAddress);
  }

  
  function judge(uint16 numberOfTeams) public {
    for(uint16 judgeIndex = 0; judgeIndex < judgeAddresses.length; judgeIndex ++) {
      address judgeAddress = judgeAddresses[judgeIndex];
      Ballot storage ballot = ballots[judgeAddress];
      if(checkBallot(ballot.hashResult, ballot.winnersIndexes, ballot.randomNumber, numberOfTeams)) {
        ballot.isValid = true;
        uint256[] memory winnersIndexes = ballot.winnersIndexes;
        for(uint16 count = 0; count < winnersIndexes.length; count ++) {
          uint256 teamIndex = winnersIndexes[count];
          if(uint16(teamWeights[teamIndex].length) != numberOfTeams + 2) {
            teamWeights[teamIndex] = new uint256[](numberOfTeams + 2);
          }
          teamWeights[teamIndex][count + 1] = teamWeights[teamIndex][count + 1] + ballot.weight;
        }
      } else {
        ballot.isValid = false;
      }
    }
    for(teamIndex = 0; teamIndex < numberOfTeams; teamIndex ++) {
      uint256 median = MathHelpers.calculateLinearMedianOfBasedOnPropabilities(teamWeights[teamIndex], 100000);
      scores.push(median);
    }
    winners = scores.sortDescendinglyWithIndeces();
  }

  function getTeamWeights(uint256 teamIndex) public view returns (uint256[] memory) {
    return teamWeights[teamIndex];
  }

  function getWinnerIndexFromJudge(address judgeAddress) public view returns(uint256[] memory){
    return(ballots[judgeAddress].winnersIndexes);
  }

  function getScores() public view  returns(uint256[]){
    return scores;
  }

  function getWinners() public view returns(uint256[]) {
    return winners;
  }
}