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
  function isBacker(address backerAddress) external view returns(bool);
  function isInParticipatedTeams(address teamAddress) external view returns(bool);
  function isBountyInProgressState() external view returns(bool);
  function isInPeriodOfDepositing() external view returns(bool);
  function isBountyInSubmitHashResultState() external view returns(bool);
  function isBountyInClosedState() external view returns(bool);
  function isBountyInSubmitRawResultState() external view returns(bool);
  function numberOfTeams() external view returns(uint16);
  function isJudged() external view returns(bool);
  function numberOfPrizes() external view returns(uint16);
}