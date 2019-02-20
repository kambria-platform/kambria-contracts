pragma solidity ^0.4.24;

import "../helpers/MathHelpers.sol";

contract MedianProtocol {
  // calcuate median score of array.
  // where scores are indexes of the array weightsOfScores
  function calculateFinalScore(uint256[] memory weightsOfScores) public pure returns (uint256) {
    // real number is not fully supported now, so to increase the accuracy we need to multiply to a value called MULTIPLE
    uint256 MULTYPLE = 100000;
    uint256 median = MathHelpers.calculateLinearMedianOfBasedOnPropabilities(weightsOfScores, MULTYPLE);
    return median;
  }
}