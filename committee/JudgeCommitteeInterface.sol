pragma solidity ^0.4.23;

interface JudgeCommitteeInterface {
  function isDeveloperJudge(address judgeAddress) external view returns(bool);
  function isBackerJudge(address candidate) external view returns(bool);
  function chooseDeveloperJudge(address candidate) external;
  function chooseBackerJudge(address candidate) external;
  function submitHashResult(bytes32 hashResult) external;
  function submitRawResult(uint256[] winnersIndexes, uint256 randomNumber) external;
  function submitHavingWinnersDecision(bool hasWinners) external;
  function getTeamsScoreFromJudge(address judgeAddress) external view returns(uint256[] memory);
  function judge() external returns(uint256[] memory winners);
  function getScores() external view returns(uint256[]);
  function getTeamWeights(uint256 teamIndex) external view returns (uint256[] memory);
}