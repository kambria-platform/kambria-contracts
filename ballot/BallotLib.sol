pragma solidity ^0.4.24;

import "./../helpers/ListHelpers.sol";
import "./../helpers/StringHelpers.sol";

library BallotLib {
  using ListHelpers for uint256[];
  using StringHelpers for uint256;
  using StringHelpers for string;
  
  enum BallotType {
    FromNoOne,
    FromDeveloperJudge,
    FromBackerJudge
  }

  enum BallotStatus {
    NotChecked,
    Valid,
    InValid
  }
  // TODO: hasWinners should be a struct because default value is false
  struct Ballot {
    BallotType ballotType;
    uint256 weight;
    bytes32 hashResult;
    uint256[] scoresForTeams;
    uint256 randomNumber;
    bool hasWinners;
    BallotStatus ballotStatus;
  }

  // valid ballot is a ballot which has:
  // randomNumber != 0
  // hash(scoresForTeams + randomNumber) = hashResult
  // scoresForTeams = 0, 1, 2, .. numberOfTeams - 1
  function checkBallot(Ballot storage ballot, uint16 numberOfTeams) internal {
    uint256 randomNumber = ballot.randomNumber;
    uint256[] memory scoresForTeams = ballot.scoresForTeams;
    // set ballot to invalid first
    ballot.ballotStatus = BallotStatus.InValid;
    if(scoresForTeams.length == 0 && randomNumber == 0) {
      return;
    }
    string memory stringToVerify = ballot.scoresForTeams.toString().concatenate(randomNumber.toString());
    if(keccak256(bytes(stringToVerify)) != ballot.hashResult){
      return;
    }
    uint256[] memory sortedIndexes = scoresForTeams.sort();
    if(!sortedIndexes.isStrictlyIncreasing()) {
      return;
    }
    if(sortedIndexes[sortedIndexes.length - 1] >= numberOfTeams){
      return;
    }
    ballot.ballotStatus = BallotLib.BallotStatus.Valid;
    return;
  }
  
  function isValid(Ballot storage ballot) internal view returns(bool){
    return ballot.ballotStatus == BallotStatus.Valid;
  }

  function isUnChecked(Ballot storage ballot) internal view returns(bool) {
    return ballot.ballotStatus == BallotStatus.NotChecked;
  }
}