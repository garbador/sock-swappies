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
        bytes32 salt = hex"abc123";
        bytes32 pr = keccak256(abi.encodePacked(uint256(123), salt));

        ss.commit(pr, "black", "XL", unicode"🧦");
        ss.register(123, salt, pr);

        vm.expectRevert();
        ss.register(123, salt, pr);

        ss.mint(address(2), 123, 1);
        vm.prank(address(2));
        // ss.setOperator(address(this), true);
        ss.approve(address(this), 123, 999);
        // console2.log(ss.allowance(address(2), address(this), 123));
        console2.log(ss.tokenURI(123));
        ss.redeem(address(2), 123, 1);
    }
}
