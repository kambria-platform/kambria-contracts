pragma solidity ^0.4.23;

library StringHelpers {
  function countCharacter(bytes bytesOfString, bytes1 bytesOfChar) internal pure returns(uint256){
    uint256 numberOfChar = 0;
    for (uint16 count = 0; count < bytesOfString.length; count++) {
      uint8 currentValue = uint8(bytesOfString[count]);
      if (currentValue == uint8(bytesOfChar[0])) {
        numberOfChar++;
      }
    }
    return(numberOfChar);
  }


  function toNumber(string str) internal pure returns(uint256){
    bytes memory byteValue = bytes(str);
    uint256 number = 0;
    for (uint16 count = 0; count < byteValue.length; count++) {
      uint8 currentValue = uint8(byteValue[count]);
      if (currentValue >= 48 && currentValue <= 57) {
        number = number * 10 + (currentValue - 48);
      } else {
        revert();
      }
    }
    return number;
  }


  function toString(uint256 number) internal pure returns(string memory) {
    if (number == 0) return "0";
    uint256 tempNumber = number;
    uint16 length;
    while (tempNumber != 0){
      length++;
      tempNumber /= 10;
    }
    bytes memory bytesOfString = new bytes(length);
    uint16 count = length - 1;
    while (number != 0){
      bytesOfString[count--] = byte(48 + number % 10);
      number /= 10;
    }
    return string(bytesOfString);
  }

// 
// Copyright (c) 2015-2016 Oraclize SRL
// Copyright (c) 2016 Oraclize LTD
// 
  function concatenate(
    string memory firstString, 
    string memory secondString, 
    string memory thirdString, 
    string memory fourthString, 
    string memory fifthString
  ) internal pure returns (string memory) {
    bytes memory firstBytes = bytes(firstString);
    bytes memory secondBytes = bytes(secondString);
    bytes memory thirdBytes = bytes(thirdString);
    bytes memory fourthBytes = bytes(fourthString);
    bytes memory fifthBytes = bytes(fifthString);

    uint totalLength = firstBytes.length + secondBytes.length + thirdBytes.length + fourthBytes.length + fifthBytes.length;
    string memory concatenatedString = new string(totalLength);
    bytes memory bytesOfConcatenatedString = bytes(concatenatedString);
    uint k = 0;
    for (uint i = 0; i < firstBytes.length; i++) bytesOfConcatenatedString[k++] = firstBytes[i];
    for (i = 0; i < secondBytes.length; i++) bytesOfConcatenatedString[k++] = secondBytes[i];
    for (i = 0; i < thirdBytes.length; i++) bytesOfConcatenatedString[k++] = thirdBytes[i];
    for (i = 0; i < fourthBytes.length; i++) bytesOfConcatenatedString[k++] = fourthBytes[i];
    for (i = 0; i < fifthBytes.length; i++) bytesOfConcatenatedString[k++] = fifthBytes[i];
    return string(bytesOfConcatenatedString);
  }


  function concatenate(
    string memory firstString, 
    string memory secondString, 
    string memory thirdString, 
    string memory fourthString
  ) internal pure returns (string memory) {
    return concatenate(firstString, secondString, thirdString, fourthString, "");
  }


  function concatenate(string memory firstString, string memory secondString, string memory thirdString) internal pure returns (string memory) {
    return concatenate(firstString, secondString, thirdString, "", "");
  }


  function concatenate(string memory firstString, string memory secondString) internal pure returns (string memory) {
    return concatenate(firstString, secondString, "", "", "");
  }
}