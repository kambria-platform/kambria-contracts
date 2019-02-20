pragma experimental "v0.5.0";
pragma experimental "ABIEncoderV2";

library Bytes {

  function concat(bytes4 selector, bytes memory data) internal pure returns (bytes memory) {
    bytes memory ret = new bytes(selector.length + data.length);
    for (uint256 i = 0; i < selector.length; i++) {
      ret[i] = selector[i];
    }
    for (uint256 j = 0; j < data.length; j++) {
      ret[j+selector.length] = data[j];
    }
    return ret;
  }

}