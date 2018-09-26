pragma solidity ^0.4.23;

interface BountyModeratorInterface {
  function getBountyIndex(address bounty) external view returns (int256);
  function newBounty(address owner, uint256 durationOfChallenge, uint256[] thePercentage) external returns (bool);
}