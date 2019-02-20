pragma solidity ^0.4.24;

interface JudgementProtocol {
  function calculateFinalScore(uint256[] weightsOfScores) external pure returns (uint256);
}