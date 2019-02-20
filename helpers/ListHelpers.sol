pragma solidity ^0.4.24;

import "./../helpers/StringHelpers.sol";
import "../helpers/SafeMath.sol";
library ListHelpers{
  using SafeMath for uint256;
  using StringHelpers for string;
  using StringHelpers for uint256;


  function isStrictlyIncreasing(uint256[] _array) internal pure returns(bool) {
    for (uint16 count = 0; count < _array.length - 1; count++){
      if(_array[count] >= _array[count + 1]) return false;
    }
    return true;
  }


  function toString(uint256[]  memory array) internal pure returns(string memory) {
    string memory result = "";
    if(array.length == 0) return result;
    string memory firstElementToString = array[0].toString();
    result = result.concatenate(firstElementToString);
    for(uint16 count = 1; count < array.length; count ++){
      string memory elementToString = array[count].toString();
      result = result.concatenate(",", elementToString);
    }
    return result;
  }


  function multiplyAll(uint256[] values, uint256 multiple) internal pure returns(uint256[]){
    uint256[] memory multipliedValues = new uint256[](values.length);
    for(uint16 count = 0; count < values.length; count ++ ){
      multipliedValues[count] = values[count].mul(multiple);
    }
    return multipliedValues;
  }


  function sort(uint256[] array) internal pure returns(uint256[]){
    quickSort(array, int(0), int(array.length - 1));
    return array;
  }
  
  
  function quickSort(uint[] memory array, int start, int end) internal pure{
    int left = start;
    int right = end;
    if(left==right) return;
    uint pivot = array[uint(start + (end - start) / 2)];
    while (left <= right) {
      while (array[uint(left)] < pivot) left++;
      while (pivot < array[uint(right)]) right--;
      if (left <= right) {
        (array[uint(left)], array[uint(right)]) = (array[uint(right)], array[uint(left)]);
        left++;
        right--;
      }
    }
    if (start < right)
      quickSort(array, start, right);
    if (left < end)
      quickSort(array, left, end);
  }

  function sum(uint256[] array) internal pure returns (uint256){
    uint256 total;
    for(uint i = 0; i < array.length; i++){
      total = total.add(array[i]);
    }
    return total;
  }

  function sum(uint256[] array, uint256 from, uint256 to) internal pure returns (uint256){
    require(from <= to && to <= array.length);
    uint256 total;
    for(uint i = from; i < to; i++){
      total = total.add(array[i]);
    }
    return total;
  }

  function includes(address[] memory array, address element) internal pure returns(int256){
    for (uint16 count = 0; count < array.length; count++) {
      if (element == array[count]) {
        return count;
      }
    }
    return -1;
  }

  function range(uint256 from, uint256 to) public pure returns(uint256[] memory array){
    require(from < to);
    array = new uint256[](to.sub(from));
    for(uint256 index = from; index < to; index ++) {
      array[index - from] = index;
    }
  }

  function swap(uint256[] memory array, uint256 firstIndex, uint256 secondIndex) public pure returns(uint256[]){
    require(firstIndex < array.length && secondIndex < array.length);
    uint256 temp = array[firstIndex];
    array[firstIndex] = array[secondIndex];
    array[secondIndex] = temp;
    return array;
  }

  function sortDescendinglyWithIndeces(uint256[] memory array) public pure returns(uint256[] memory) {
    uint256 arrayLength = array.length;
    uint256[] memory indexes = range(0, arrayLength);
    for (uint256 i = 0; i < arrayLength; i++){// Last i elements are already in place    
      for (uint256 j = 0; j < arrayLength-i-1; j++) {
        if (array[j] < array[j+1]){
          swap(array, j, j+1);
          swap(indexes, j, j + 1);
        }
      }
    }
    return indexes; 
  }

  function sortAscendinglyWithIndeces(uint256[] memory array) public pure returns(uint256[] memory) {
    uint256 arrayLength = array.length;
    uint256[] memory indexes = range(0, arrayLength);
    for (uint256 i = 0; i < arrayLength; i++){// Last i elements are already in place    
      for (uint256 j = 0; j < arrayLength-i-1; j++) {
        if (array[j] > array[j+1]){
          swap(array, j, j+1);
          swap(indexes, j, j + 1);
        }
      }
    }
    return indexes; 
  }

  function getIndexesOfMaxValues(uint256[] memory array, uint16 numberOfMaxValues) internal pure returns(uint256[] memory){
    require(numberOfMaxValues <= array.length);
    uint256[] memory sortedIndeces = sortDescendinglyWithIndeces(array);
    return slice(sortedIndeces, 0, numberOfMaxValues);
  }

  function slice(uint256[] array, uint16 from, uint16 to) internal pure returns(uint256[] memory){
    require(from <= to && to <= array.length);
    uint256[] memory slicedArray = new uint256[](to - from);
    for(uint16 index = from; index < to; index ++) {
      slicedArray[index - from] = array[index];
    }
    return slicedArray;
  }
}

