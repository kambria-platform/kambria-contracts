pragma solidity ^0.4.23;

interface JudgeInterface {
  function judgeList(address bounty) external view returns (address[]);
  function getChallengeWinners(address bounty) external view returns (address[]);
}