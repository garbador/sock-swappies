// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {SockSwap} from "../src/SockSwap.sol";

contract SockPuppet is Test {
    SockSwap public ss;

    function setUp() public {
        ss = new SockSwap();
    }

    function test_name() public {
        console2.log(ss.name());
        console2.log(ss.symbol());
    }

    function test_ownership() public {
        vm.prank(address(0x69));
        vm.expectRevert();
        ss.setRules(address(1));
    }

    function test_lessgo() public {
        ss.register(123, "black", "XL", unicode"🧦");
        vm.expectRevert();
        ss.register(1, "", "", "");
        console2.log(ss._regCheck(1));
        ss.mint(address(2), 123, 1);
        vm.prank(address(2));
        // ss.setOperator(address(this), true);
        ss.approve(address(this), 123, 999);
        console2.log(ss.allowance(address(2), address(this), 123));
        // console2.log(ss.tokenURI(123));
        ss.redeem(address(2), 123, 1);
    }
}
