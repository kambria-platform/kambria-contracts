pragma solidity ^0.4.23;
import "../helpers/ListHelpers.sol";
import "../ballot/BallotLib.sol";


contract BallotLibMock {
  using BallotLib for BallotLib.Ballot;
  BallotLib.Ballot public ballot;
  function setBallot(
    bytes32 hashResult, 
    uint256[] memory scoresForTeams, 
    uint256 randomNumber, 
    uint256 weight,
    BallotLib.BallotType ballotType, 
    bool hasWinners
  ) public {
    ballot.hashResult = hashResult;
    ballot.scoresForTeams = scoresForTeams;
    ballot.randomNumber = randomNumber;
    ballot.ballotType = ballotType;
    ballot.weight = weight;
    ballot.hasWinners = hasWinners;
  }

  function checkBallot(uint16 numberOfTeams) public {
    ballot.checkBallot(numberOfTeams);
  }

  function isValid() public view returns(bool){
    return ballot.isValid();
  }
}