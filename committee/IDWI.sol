pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";

// ** NOTICE **
// This lib is only ultilized for KAT unit, not wei-KAT.
// Fault Tolerance: 9 candidates

contract IDWI {
  using SafeMath for uint256;

  // Both are larger and more accurated
  // But:
  // If DECIMALS is too large, it causes overflow memory
  // If DENSITY is too large, it causes a huge computation
  // Accurated condition: log(DECIMALS) > 2 * 4 * log(DENSITY)
  uint256 DECIMALS = 10 ** 9; 
  uint256 DENSITY = 10 ** 1;

  modifier faultTolerance(uint256[] samples) {
    require(samples.length >= 2 && samples.length <= 9);
    _;
  }

  // Original: |a-b| = 1/(a-b)^4
  // Scale with DECIMALS: DECIMALS * |a-b| = DECIMALS/(a-b)^4
  function norm(uint256 a, uint256 b) public view returns (uint256) {
    uint256 _sub;
    if(a >= b) _sub = a.sub(b);
    else _sub = b.sub(a);

    if(_sub == 0) return 0;
    return DECIMALS.div(_sub ** 4);
  }

  function weigthAt(uint256 a, uint256[] samples) public view faultTolerance(samples) returns (uint256) {
    uint256 totalNorm = 0;
    uint256 totalComposition = 0;

    for(uint256 i = 0; i < samples.length; i++) {
      uint256 _norm = norm(a, i.mul(DENSITY));
      if(_norm == 0) return samples[i];

      totalNorm = totalNorm.add(_norm);
      totalComposition = totalComposition.add(_norm.mul(samples[i]));
    }

    return totalComposition.div(totalNorm);
  }

  function totalWeight(uint256[] samples) public view faultTolerance(samples) returns (uint256) {
    uint256 _total;
    for(uint256 i = 0; i <= (samples.length - 1) * DENSITY; i++) {
      _total = _total.add(weigthAt(i, samples));
    }
    return _total;
  }

  function median(uint256[] samples) public view faultTolerance(samples) returns (uint256) {
    uint256 _point = 0;
    uint256 _value = 0;
    uint256 _threshold = totalWeight(samples).div(2);
    for(uint256 i = 0; i <= (samples.length - 1) * DENSITY; i++) {
      _point = i;
      _value = _value.add(weigthAt(i, samples));
      if(_value >= _threshold) break;
    }
    return _point;
  }
}