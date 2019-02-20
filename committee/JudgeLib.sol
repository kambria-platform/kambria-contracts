pragma solidity ^0.4.24;

library JudgeLib {
  enum JudgeType {
    NoRole,
    DeveloperJudge,
    BackerJudge
  }
  
  struct Judge {
    JudgeType judgeType;
    uint256 depositedAmount;
  }

  function isDeveloperJudge(Judge storage judge) public view returns(bool) {
    return judge.judgeType == JudgeType.DeveloperJudge;
  }

  function isBackerJudge(Judge storage judge) public view returns(bool) {
    return judge.judgeType == JudgeType.BackerJudge;
  }
}