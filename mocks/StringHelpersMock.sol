pragma solidity ^0.4.24;

import "../helpers/StringHelpers.sol";

library StringHelpersMock {
  using StringHelpers for *;
  using StringHelpers for uint256;
  

  function concatenateFiveStrings(
    string firstString, 
    string secondString,
    string thirdString,
    string fourthString,
    string fifthString
    ) public pure returns(string) {
    return firstString.concatenate(
      secondString,
      thirdString,
      fourthString,
      fifthString
    );
  }

  
  function concatenateFourStrings(
    string firstString, 
    string secondString,
    string thirdString,
    string fourthString
    ) public pure returns(string) {
    return firstString.concatenate(
      secondString,
      thirdString,
      fourthString
    );
  }

  
  function concatenateThreeStrings(
    string firstString, 
    string secondString,
    string thirdString
    ) public pure returns(string) {
    return firstString.concatenate(
      secondString,
      thirdString
    );
  }

  
  function concatenateTwoStrings(
    string firstString, 
    string secondString
    ) public pure returns(string) {
    return firstString.concatenate(
      secondString
    );
  }


  function countCharacter(bytes bytesOfString, bytes1 bytesOfChar) public pure returns(uint256){
    return bytesOfString.countCharacter(bytesOfChar);
  }


  function convertToNumber(string str) public pure returns(uint256){
    return str.toNumber();
  }


  function convertToString(uint256 number) public pure returns(string memory){
    return number.toString();
  }
}