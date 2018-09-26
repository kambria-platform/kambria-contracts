pragma solidity ^0.4.23;

interface BountyInterface {
  function TOTAL_DEPOSIT() external view returns (uint256);
  function MODERATOR() external view returns (address);
  function TOKEN() external view returns (address);
  function JUDGE() external view returns (address);
  function VALUE_CAPTURED() external view returns (address);
  function START() external view returns (uint256);
  function DURATION_OF_CHALLENGE() external view returns (uint256);
  function THE_CURRENT_PERCENTAGES(uint256 _index) external view returns (uint256);
  function THE_CURRENT_NUMBER_OF_SPONSORS() external view returns (uint256);
  function sponsors(address _sponsor) external view returns (uint256);
}