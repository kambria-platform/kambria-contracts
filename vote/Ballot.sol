pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";

contract Ballot {
  using SafeMath for uint256;

  address public MODERATOR;
  uint256 public START;
  uint256 public END;
  uint256 public RATE;
  bytes32[] public CANDIDATE_IDENTITIES;
  mapping(address => bytes32) public votes;

  event VoteFor(address indexed sender, bytes32 cid);

  modifier onlyModerator() {
    require(msg.sender == MODERATOR);
    _;
  }

  modifier mustBeEnded() {
    require(END != 0);
    _;
  }

  modifier mustBeVoting() {
    require(END == 0);
    _;
  }

  constructor(address moderator, uint256 rate, bytes32[] cids) public {
    MODERATOR = moderator;
    START = block.number;
    END = 0;
    RATE = 10 ** rate; // Recommend rate = 12
    CANDIDATE_IDENTITIES = cids;
  }

  function end() public onlyModerator mustBeVoting {
    END = block.number;
  }

  function restart() public onlyModerator mustBeEnded {
    END = 0;
  }

  function() public payable mustBeVoting {
    uint256 value = msg.value;
    msg.sender.transfer(msg.value);

    uint256 vote = value.div(RATE);
    require(vote >= 0 && vote < CANDIDATE_IDENTITIES.length);
    votes[msg.sender] = CANDIDATE_IDENTITIES[vote];
    emit VoteFor(msg.sender, votes[msg.sender]);
  }
}