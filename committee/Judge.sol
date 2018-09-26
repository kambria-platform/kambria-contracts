pragma solidity ^0.4.23;

import "./../helpers/Ownable.sol";

contract Judge is Ownable {
  mapping(address => address[]) public whoWinTheChallenge;
  mapping(address => address[]) public judgeList;

  event AddJudge(address indexed bounty, address[] judges);
  event SetWinner(address indexed bounty, address[] winners);

  function addJudge(address bounty, address[] judges) public onlyOwner returns (bool) {
    judgeList[bounty] = judges;
    emit AddJudge(bounty, judges);
    return true;
  }

  function setWinner(address bounty, address[] winners) public onlyOwner returns (bool) {
    whoWinTheChallenge[bounty] = winners;
    emit SetWinner(bounty, winners);
    return true;
  }

  function getChallengeWinners(address bounty) public view returns (address[]) {
    return whoWinTheChallenge[bounty];
  }
}