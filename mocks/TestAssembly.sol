pragma solidity^0.4.24;

contract Test {
    // Reads strings from memory ('a' and 'b' are pointers to memory).
  // function equalUsingAssembly(string memory a, string memory b) public view returns (bool) {
  //   assembly {
  //     let res := 0
  //     let lA := mload(a)   // lA address is 0x60
  //     let lB := mload(b)
  //     jumpi(tag_compare, eq(lA, lB))
  //     tag_finalize:
  //       mstore(0x0, res)
  //       return(0x0, 32)
  //     tag_compare:
  //       {
  //         let i := 0
  //         let words := div(add(lA, 31), 32) // Total number of words. Basically: ceil(lengthOfA / 32)
  //         let offsetA := add(a, 32)
  //         let offsetB := add(b, 32)
  //         tag_loop:
  //           {
  //             let offset := mul(i, 32)
  //             i := add(i, 1)
  //             res := eq(mload(add(offsetA, offset)), mload(add(offsetB, offset)))
  //           }
  //           jumpi(tag_loop, and(lt(i, words), res) )
  //         }
  //     jump(tag_finalize)
  //   }
  // }
  
  function equalUsingKeccak(string memory a, string memory b) public view returns(bool){
    return keccak256(abi.encode(a)) == keccak256(abi.encode(b));
  }
}