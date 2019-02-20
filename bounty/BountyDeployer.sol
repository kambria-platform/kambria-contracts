pragma solidity ^0.4.24;
import "./Bounty.sol";
// not using now
library BountyDeployer {
  function deployNewBounty(
    address db, 
    uint256[4] bountyTimeStamps,
    uint256[] thePercentage,
    address owner
  ) public returns(Bounty) {
    return new Bounty(
      db,
      bountyTimeStamps,
      thePercentage,
      owner
    );
  }
}