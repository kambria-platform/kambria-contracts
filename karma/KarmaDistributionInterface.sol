pragma solidity ^0.4.23;

interface KarmaDistributionInterface {
  function distributeKarmaToBounty(address _bountyAddress) external returns (bool);
  function totalSupply() external view returns (uint256);
  function totalSupplyAt(uint256 _blockNumber) external view returns (uint256);
  function karmaOf(address _owner) external view returns (bool);
  function karmaOfAt(address _owner, uint256 _blockNumber) external view returns (uint256);
}