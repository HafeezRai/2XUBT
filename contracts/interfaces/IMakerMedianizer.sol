pragma solidity ^0.5.5;

interface IMakerMedianizer {
    function read() external view returns (bytes32);
}
