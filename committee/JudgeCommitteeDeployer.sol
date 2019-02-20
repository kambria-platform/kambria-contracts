pragma solidity ^0.4.24;
import "./JudgeCommittee.sol";
library JudgeCommitteeDeployer {
  function deployJudgeCommittee(
    address db,
    address bountyAddress
  ) public returns(JudgeCommittee) {
    return new JudgeCommittee(db, bountyAddress);
  }
}