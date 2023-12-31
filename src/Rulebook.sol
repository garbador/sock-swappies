// SPDX-License-Identifier: MIT+RTL
pragma solidity ^0.8.21;
import "./interfaces.sol";

contract CarteBlanche is IRulebook {
    uint32 public timeout = 0;
    address immutable daSwap;

    constructor(address parent) {
        daSwap = parent;
    }

    function check(uint256 id) external view returns (bool) {
        return !ISockSwap(daSwap)._regCheck(id);
    }

    function exists(uint256 id, uint256 _amount) external view returns (bool) {
        return ISockSwap(daSwap)._regCheck(id);
    }
}
