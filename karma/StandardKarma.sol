pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";

contract StandardKarma {
  using SafeMath for uint256;

  struct Checkpoint {
    uint256 fromBlock;
    uint256 value;
  }
  Checkpoint[] totalSupplyHistory;
  mapping (address => Checkpoint[]) balancesHistory;

  function totalSupply() public view returns (uint256) {
    return findCheckpoint(totalSupplyHistory, block.number);
  }

  function totalSupplyAt(uint256 _blockNumber) public view returns (uint256) {
    return findCheckpoint(totalSupplyHistory, _blockNumber);
  }

  function karmaOf(address _owner) public view returns (uint256) {
    return findCheckpoint(balancesHistory[_owner], block.number);
  }

  function karmaOfAt(address _owner, uint256 _blockNumber) public view returns (uint256) {
    return findCheckpoint(balancesHistory[_owner], _blockNumber);
  }

  function findCheckpoint(Checkpoint[] memory _checkpoints, uint256 _blockNumber) private pure returns (uint256) {
    if (_checkpoints.length > 0 && _blockNumber > 0) {
      uint256 min = 0;
      uint256 mid = 0;
      uint256 max = _checkpoints.length.sub(1);
      while (max > min) {
        mid = min.add(max).add(1).div(2);
        if (_checkpoints[mid].fromBlock <= _blockNumber) {
          min = mid;
        } else {
          max = mid.sub(1);
        }
      }
      return _checkpoints[min].value;
    } else {
      return 0;
    }
  }

  function mint(address _owner, uint256 _value) internal returns (bool) {
    // Update totalSupply
    uint256 _newTotalSupplyHistory;
    if (totalSupplyHistory.length > 0) {
      _newTotalSupplyHistory = totalSupplyHistory[totalSupplyHistory.length.sub(1)].value.add(_value);
    } else {
      totalSupplyHistory.push(Checkpoint(0,0));
      _newTotalSupplyHistory = _value;
    }
    if (totalSupplyHistory[totalSupplyHistory.length.sub(1)].fromBlock == block.number) {
      totalSupplyHistory[totalSupplyHistory.length.sub(1)].value = _newTotalSupplyHistory;
    } else {
      Checkpoint memory _totalSupplyHistory = Checkpoint(block.number, _newTotalSupplyHistory);
      totalSupplyHistory.push(_totalSupplyHistory);
    }

    // Update balancesHistory
    uint256 _newBalancesHistory;
    if (balancesHistory[_owner].length > 0) {
      _newBalancesHistory = balancesHistory[_owner][balancesHistory[_owner].length.sub(1)].value.add(_value);
    } else {
      balancesHistory[_owner].push(Checkpoint(0,0));
      _newBalancesHistory = _value;
    }
    if (balancesHistory[_owner][balancesHistory[_owner].length.sub(1)].fromBlock == block.number) {
      balancesHistory[_owner][balancesHistory[_owner].length.sub(1)].value = _newBalancesHistory;
    } else {
      Checkpoint memory _balancesHistory = Checkpoint(block.number, _newBalancesHistory);
      balancesHistory[_owner].push(_balancesHistory);
    }

    return true;
  }

}