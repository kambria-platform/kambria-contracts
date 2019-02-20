// pragma solidity ^0.4.23;

// import "../../contracts/committee/MedianJudgement.sol";
// contract MedianJudgementMock is MedianJudgement {
//   function getFromBackerJudgeBallotType() public pure returns(BallotTypes.BallotType){
//     return BallotTypes.BallotType.FromBackerJudge;
//   }

//   function getFromDeveloperJudgeBallotType() public pure returns(BallotTypes.BallotType){
//     return BallotTypes.BallotType.FromDeveloperJudge;
//   }

//   function createNewBallot(
//     bytes32 _encryptedVote, 
//     string _keyToDecrypt, 
//     BallotTypes.BallotType _ballotType, 
//     uint256 _amount) public pure returns(bool){
//     Ballot memory newBallot = Ballot(_encryptedVote, _keyToDecrypt, _ballotType, _amount);
//     if (newBallot.amount != 0) return true;
//     return false;
//   }

// }