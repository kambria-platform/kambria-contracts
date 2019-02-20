pragma solidity ^0.4.23;
import "../helpers/ListHelpers.sol";
contract ListHelpersMock {
  using ListHelpers for uint[];
  using ListHelpers for uint256[];
  using ListHelpers for uint128[];
  using ListHelpers for address[];


  function isStrictlyIncreasingArray(uint256[] array) public pure returns(bool){
    return array.isStrictlyIncreasing();
  }


  function convertListToString(uint256[] array) public pure returns(string) {
    return array.toString();
  }


  function multiplyAll(uint256[] values, uint256 multiple) public pure returns(uint256[]){
    return values.multiplyAll(multiple);
  }


  function sort(uint256[] array) public pure returns(uint256[]){
    return array.sort();
  }

  function sum(uint256[] memory array, uint16 from, uint16 to) public pure returns(uint256) {
    return array.sum(from, to); 
  }
  
  
  function includes(address[] array, address element) public pure returns(int256){
    return array.includes(element);
  }

  function swap(uint256[] memory array, uint256 firstIndex, uint256 secondIndex) public pure returns(uint256[]){
    return array.swap(firstIndex, secondIndex);
  }

  function sortDescendinglyWithIndeces(uint256[] memory array) public pure returns(uint256[] memory) {
    return array.sortDescendinglyWithIndeces(); 
  }

  function sortAscendinglyWithIndeces(uint256[] memory array) public pure returns(uint256[] memory) {
    return array.sortAscendinglyWithIndeces(); 
  }

  function slice(uint256[] memory array, uint16 from, uint16 to) public pure returns(uint256[] memory) {
    return array.slice(from, to); 
  }

  function getIndexesOfMaxValues(uint256[] memory array, uint16 numberOfMaxValue) public pure returns(uint256[] memory){
    return array.getIndexesOfMaxValues(numberOfMaxValue);
  }
}