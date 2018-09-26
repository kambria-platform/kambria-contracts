pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";
import "./Ballot.sol";

contract VoteModerator is Ownable {
  uint256 public MAX_CANDIDATES;
  address[] public ballots;

  event ChangeMaxCandidates(address indexed owner, uint256 maxcan);
  event NewBallot(address indexed owner, address ballot);
  event EndBallot(address indexed owner, address ballot, bool success);
  event RestartBallot(address indexed owner, address ballot, bool success);

  constructor() public {
    MAX_CANDIDATES = 100;
  }

  function changeMaxCandidates(uint256 maxcan) public onlyOwner returns (bool) {
    require(maxcan > 0);
    MAX_CANDIDATES = maxcan;
    emit ChangeMaxCandidates(msg.sender, maxcan);
    return true;
  }

  function getTotalBallots() public view returns (uint256) {
    return ballots.length;
  }

  function getSBID(address ballot) public view returns (uint256) {
    for (uint256 i = 0; i < ballots.length; i++) {
      if (ballot == ballots[i]) {
        return i;
      }
    }
  }
  
  // rate:
  // cids: Array of candidate identities
  function newBallot(uint256 rate, bytes32[] cids) public onlyOwner returns (bool) {
    require(cids.length > 0 && cids.length <= MAX_CANDIDATES);
    Ballot _ballot = new Ballot(this, rate, cids);
    ballots.push(_ballot);
    emit NewBallot(msg.sender, _ballot);
    return true;
  }

  // sbid: Sequence Ballot Identity
  function endBallot(uint256 sbid) public onlyOwner returns (bool) {
    require(sbid >= 0 && sbid < ballots.length);
    bool success = ballots[sbid].call(keccak256("end()"));
    emit EndBallot(msg.sender, ballots[sbid], success);
    return success;
  }

  // sbid: Sequence Ballot Identity
  function restartBallot(uint256 sbid) public onlyOwner returns (bool) {
    require(sbid >= 0 && sbid < ballots.length);
    bool success = ballots[sbid].call(keccak256("restart()"));
    emit RestartBallot(msg.sender, ballots[sbid], success);
    return success;
  }
}