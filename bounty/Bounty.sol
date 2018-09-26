pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";
import "./../committee/JudgeInterface.sol";
import "./../token/TokenInterface.sol";


contract Bounty {
  using SafeMath for uint256;

  address public MODERATOR;
  address public TOKEN;
  address public JUDGE;
  address public VALUE_CAPTURED;
  uint256 public START;
  uint256 public DURATION_OF_CHALLENGE;
  uint256[] public THE_CURRENT_PERCENTAGES;
  uint256 public THE_CURRENT_NUMBER_OF_SPONSORS;
  uint256 public TOTAL_DEPOSIT;
  mapping(address => uint) public sponsors;

  event Deposit(address indexed who, uint256 value);
  event Withdraw(address indexed who, uint256 value);

  modifier inPeriodOfDepositing() {
    require(block.timestamp <= START.add(DURATION_OF_CHALLENGE));
    _;
  }

  modifier inPeriodOfWithdrawing() {
    require(block.timestamp > START.add(DURATION_OF_CHALLENGE));
    _;
  }


  constructor (
    address token,
    address judge,
    address valueCaptured,
    uint256 durationOfChallenge,
    uint256[] thePercentages
  ) public {
    MODERATOR = msg.sender;
    TOKEN = token;
    JUDGE = judge;
    VALUE_CAPTURED = valueCaptured;
    START = block.timestamp;
    DURATION_OF_CHALLENGE = durationOfChallenge;
    THE_CURRENT_PERCENTAGES = thePercentages;
  }

  function isInList(address winner, address[] winnersList) private pure returns (int256) {
    for (uint256 i = 0; i < winnersList.length; i++) {
      if (winner == winnersList[i]) {
        return int256(i);
      }
    }
    // Dont exist in list
    return -1;
  }

  function totalPercentage(uint256 from, uint256 to) private view returns (uint256) {
    require(from >= 0);
    require(to <= THE_CURRENT_PERCENTAGES.length);
    uint256 total = 0;
    for (uint256 i = from; i < to; i++) {
      total = total.add(THE_CURRENT_PERCENTAGES[i]);
    }
    return total;
  }

  function deposit() public inPeriodOfDepositing returns (bool) {
    // Transfer token and record sponsor
    uint256 value = TokenInterface(TOKEN).allowance(msg.sender, this);
    TokenInterface(TOKEN).transferFrom(msg.sender, this, value);
    TOTAL_DEPOSIT = TOTAL_DEPOSIT.add(value);
    emit Deposit(msg.sender, value);
    if (sponsors[msg.sender] > 0) {
      // Re-deposit
      sponsors[msg.sender] = sponsors[msg.sender].add(value);
    } else {
      // Newly deposit
      THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.add(1);
      sponsors[msg.sender] = value;
    }
    return true;
  }

  function depositFrom(address sponsor) public inPeriodOfDepositing returns (bool) {
    // Transfer token and record sponsor
    uint256 value = TokenInterface(TOKEN).allowance(sponsor, this);
    TokenInterface(TOKEN).transferFrom(sponsor, this, value);
    emit Deposit(sponsor, value);
    if (sponsors[sponsor] > 0){
      // Re-deposit
      sponsors[sponsor] = sponsors[sponsor].add(value);
    } else {
      // Newly deposit
      THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.add(1);
      sponsors[sponsor] = value;
    }
    return true;
  }

  function withdraw() public inPeriodOfWithdrawing returns (bool) {
    address[] memory winners = JudgeInterface(JUDGE).getChallengeWinners(address(this));
    uint256 remainer = TokenInterface(TOKEN).balanceOf(address(this));

    // Cannot withdraw if the remainer is zero
    require(remainer > 0);

    // Sponsors withdraw
    if (winners.length == 0) {
      require(THE_CURRENT_NUMBER_OF_SPONSORS > 0);
      require(sponsors[msg.sender] > 0);

      if (THE_CURRENT_NUMBER_OF_SPONSORS > 1) {
        TokenInterface(TOKEN).transfer(msg.sender, sponsors[msg.sender]);
        emit Withdraw(msg.sender, sponsors[msg.sender]);
        sponsors[msg.sender] = 0;
        THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.sub(1);
      } else {
        TokenInterface(TOKEN).transfer(VALUE_CAPTURED, remainer.sub(sponsors[msg.sender])); // Tranfer to Value-Captured
        emit Withdraw(VALUE_CAPTURED, remainer.sub(sponsors[msg.sender]));
        TokenInterface(TOKEN).transfer(msg.sender, sponsors[msg.sender]);
        emit Withdraw(msg.sender, sponsors[msg.sender]);
        sponsors[msg.sender] = 0;
        THE_CURRENT_NUMBER_OF_SPONSORS = THE_CURRENT_NUMBER_OF_SPONSORS.sub(1);
      }
      return true;
    }

    // Winners withdraw
    int256 index = isInList(msg.sender, winners);
    if (index >= 0) {
      uint256 prize = uint256(index);
      uint256 reward = remainer.mul(THE_CURRENT_PERCENTAGES[prize]).div(totalPercentage(0, THE_CURRENT_PERCENTAGES.length));
      TokenInterface(TOKEN).transfer(msg.sender, reward);
      emit Withdraw(msg.sender, reward);
      THE_CURRENT_PERCENTAGES[prize] = 0;
      if (totalPercentage(0, THE_CURRENT_PERCENTAGES.length.sub(1)) == 0) {
        TokenInterface(TOKEN).transfer(VALUE_CAPTURED, remainer.sub(reward));
        emit Withdraw(VALUE_CAPTURED, remainer.sub(reward));
      }
      return true;
    }

    revert();
  }
}