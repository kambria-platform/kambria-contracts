pragma solidity ^0.4.23;

import "./../helpers/SafeMath.sol";
import "./../helpers/ListHelpers.sol";
library MathHelpers {
  using SafeMath for uint256;
  using SafeMath for int256;
  using ListHelpers for uint256[];

  
  // propability of a scores[i] is equal weights[i] * score[i]/total(weights[j] * score[j]) where j = 0..weights.length
  // all values of propabilities are devided by total(weights[j] * score[j]), 
  // so we use weightedValues = propabilities * total(weights[j] * score[j])
  // to calculate median. This change will not affect to median score which is our expexted value.
  // Usually the gap between score is small(usually equal 1) 
  // and in solidity the real number is not fully supported that is why we need to multiply to a multiple (=10000)
  // in order to increase the accuracy of the function
  function calculateLinearMedianOfBasedOnPropabilities(
    uint256[] weights, 
    // uint256[] scores,
    uint256 multiple
  ) public pure returns(uint256) {
    uint256[] memory weightedValues = weightedValuesOf(weights);
    return caculateLinearMedian(multiple, weightedValues);
  }


  function weightedValuesOf(uint256[] weights) public pure returns(uint256[]){
    // require(values.length == weights.length);
    uint256[] memory weightedValues = new uint256[](weights.length);
    for(uint256 count = 0; count < weights.length; count ++){
      // uint256 value = count;
      uint256 weight = weights[count];
      weightedValues[count] = count.mul(weight);
    }
    return (weightedValues);
  }


  function caculateLinearMedian(uint256 multiple, uint256[] values) public pure returns(uint256){
    // require(indexes.length == values.length);
    // require(indexes.isStrictlyIncreasing());
    uint256 currentArea = 0;
    uint256 pastArea = 0;
    uint256 doubleOfTotalArea = multiple.mul(sum(values)).mul(2);
    for (uint256 count = 1; count < values.length; count ++){
      pastArea = currentArea;
      // uint256 parallelSide1 = values[count];
      // uint256 parallelSide2 = values[count-1];
      // uint256 height = multiple;
      uint256 areaOfNextPart = calculateDoubleTrapeziumArea(values[count], values[count-1], multiple);
      currentArea = currentArea + areaOfNextPart;
      if (currentArea.mul(2) > doubleOfTotalArea){
        uint256 missingArea = doubleOfTotalArea.div(2) - pastArea;
        uint256 medianX = solveIntegralOfLinearFunction(
          [multiple.mul(count-1),values[count-1]], 
          [multiple.mul(count),values[count]], 
          missingArea.div(2)
        )[0];
        return medianX;
      }
    }
  }

  function sum(uint256[] array) public pure returns (uint256){
    uint256 total;
    for(uint i = 0; i < array.length; i++){
      total = total.add(array[i]);
    }
    return total;
  }

  function sum(uint256[] array, uint256 from, uint256 to) public pure returns (uint256){
    require(from >= 0 && from <= to && to < array.length);
    uint256 total;
    for(uint i = from; i < to; i++){
      total = total.add(array[i]);
    }
    return total;
  }

  function solveIntegralOfLinearFunction(
    uint256[2] _startPoint, 
    uint256[2] _endPoint, 
    uint256 _expectedArea
  ) public pure returns(uint256[2]){
    require(_startPoint[0] <= _endPoint[0]);
    uint256 doubleOfTotalArea = calculateDoubleTrapeziumArea(_startPoint[1], _endPoint[1], caluculateDistance(_startPoint[0], _endPoint[0]));
    require(doubleOfTotalArea >= _expectedArea.mul(2));
    if(caluculateDistance(_startPoint[0], _endPoint[0]) <= 1) {
      return(_startPoint);
    }
    uint256 middleX = _startPoint[0].add(_endPoint[0]).div(2);
    uint256 middleY = _startPoint[1].add(_endPoint[1]).div(2);
    uint256 doubleOfAreaFromStartToMiddlePoint = calculateDoubleTrapeziumArea(_startPoint[1], middleY, middleX.sub(_startPoint[0]));
    if(doubleOfAreaFromStartToMiddlePoint > _expectedArea.mul(2)){
      return solveIntegralOfLinearFunction(_startPoint, [middleX, middleY], _expectedArea);
    } else {
      return solveIntegralOfLinearFunction([middleX, middleY], _endPoint, _expectedArea.mul(2).sub(doubleOfAreaFromStartToMiddlePoint).div(2));
    }
  }


  function caluculateDistance(uint256 _value1, uint256 _value2) public pure returns(uint256){
    if(_value1 > _value2) return (_value1 - _value2);
    return _value2 - _value1;
  }
  

  /**
  line equation is multiple * y = multiple * slope * x + multiple * verticalIntercept
  where multiple, multiple * slope and multiple * verticalIntercept are integers
  */
  // TODO: this function is not neccessary now. we can remove it.
  function findLineEquationWithTwoPoints(uint256[2] _point1, uint256[2] _point2) 
    public pure returns(int256, int256, int256){
    require(_point1[0] != _point2[0]);
    // TODO: the range of uint256 and int256 are different, so these lines of code need to be modified.
    int256 multiple = int256(_point1[0] - _point2[0]);
    int256 multipleMultiplySlope = int256(_point1[1] - _point2[1]);
    int256 multipleMultiplyVerticalIntercept = int256(_point1[0] * _point2[1] - _point1[1] * _point2[0]);
    return(multiple, multipleMultiplySlope, multipleMultiplyVerticalIntercept);
  }


  function calculateDoubleOfTotalArea(uint256[] values, uint256[] indexes) public pure returns(uint256) {
    require(indexes.length == values.length);
    require(indexes.isStrictlyIncreasing());
    uint256 doubleTotalArea;
    for(uint16 count = 0; count < indexes.length - 1; count ++) {
      doubleTotalArea = doubleTotalArea + calculateDoubleTrapeziumArea(values[count], values[count+1], indexes[count + 1] - indexes[count]);
    }
    return doubleTotalArea;
  }


  // TradeziumArea = 1/2 * (parallelSide1 + parallelSide2) * height
  function calculateDoubleTrapeziumArea (uint256 parallelSide1, uint256 parallelSide2, uint256 height) public pure returns(uint256){
    return parallelSide1.add(parallelSide2).mul(height);
  }


  function calculateTotalWeightedValue(uint256[] values, uint256[] weights) public pure returns(uint256){
    require(values.length == weights.length);
    uint256 totalWeightedValue = 0;
    for(uint16 count = 0; count < values.length; count ++){
      totalWeightedValue = totalWeightedValue + values[count] * weights[count];
    }
    return totalWeightedValue;
  }
}