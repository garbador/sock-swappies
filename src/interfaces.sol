// SPDX-License-Identifier: MIT+RTL

pragma solidity ^0.8.21;

interface ISockSwap {
    function _regCheck(uint256 id) external view returns (bool registered);
}

interface IRulebook {
    // when can you dispute
    function timeout() external view returns (uint256);

    // is this an unidentified sock
    function check(uint256 id) external view returns (bool valid);

    // there exist this many of an existing identified sock
    function exists(uint256 id, uint256 amount) external returns (bool valid);

    // is this the sock you claim it is
    // function print(uint256 id, address to, uint256 amount) external payable;

    // did you get your sock
    // function redeem(uint256 id, address from, uint256 amount) external;
}
