// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.21;

import {Test, console2} from "forge-std/Test.sol";
import {SockSwap} from "../src/SockSwap.sol";
import {RealRulebook} from "../src/RealRulebook.sol";
import "../src/interfaces.sol";

contract SockPuppet is Test {
    SockSwap public ss;
    bytes32 YES = bytes32(uint256(1));
    bytes32 NO = bytes32(uint256(0));

    function setUp() public {
        ss = new SockSwap();
    }

    function setup_reality() public returns (address) {
        if (block.chainid == 1) return 0x5b7dD1E86623548AF054A4985F7fc8Ccbb554E2c;
        if (block.chainid == 5) return 0x6F80C5cBCF9FbC2dA2F0675E56A5900BB70Df72f;
        if (block.chainid == 17000) return 0xd3575b215EC1c3875ad7890982f95EA729DF9537;
        if (block.chainid == 11155111) return 0xaf33DcB6E8c5c4D9dDF579f53031b514d19449CA;
        address irlAddr = address(0);
        // fork one of the above networks or find the source to deploy locally
        /*
        irlAddr = makeAddr("realitea");
        deployCodeTo("RealityETH_v3_0.sol", irlAddr);
        */
        // -- OR --
        /*
        bytes memory creation_bytecode = hex"GPL'd code";
        assembly {
            irlAddr := create(0, add(creation_bytecode, 0x20), mload(creation_bytecode))
        }
        require(irlAddr != address(0), "deployment failed.");
        */
        return irlAddr;
    }

    function test_name() public {
        string memory name = ss.name();
        assertGe(bytes(name).length, 0);
        console2.log(name);
        console2.log(ss.symbol());
    }

    function test_ownership() public {
        vm.prank(address(0x69));
        vm.expectRevert();
        ss.setRules(address(1), true);
    }

    function test_mock_basics() public {
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

    function test_reality_deploy() public {
        address irlAddr = setup_reality();
        IRealityETH irl = IRealityETH(irlAddr);

        bytes32 qb = irl.askQuestion(
            0,
            unicode"Does reality.eth support Foundry?␟arts␟en_US",
            address(0),
            120,
            123,
            0
        );

        vm.expectRevert();
        // [FAIL. Reason: question must be finalized]
        irl.resultFor(qb);
        vm.warp(123);
        irl.submitAnswer{value:1}(qb, YES, 0);
        vm.warp(243);
        bytes32 res = irl.resultFor(qb);
        assertEq(uint(res), 1);

        bytes32 qu = irl.askQuestion(
            1,
            unicode"how much wood could a woodchuck chuck?␟arts␟en_US",
            address(0),
            1,
            0,
            0
        );
        irl.submitAnswer{value:1}(qu, bytes32(uint256(9001)), 0);
        vm.warp(244);
        assertEq(uint256(irl.resultFor(qu)), 9001);
    }

    function test_irl_socks() public {
        address irlAddr = setup_reality();
        IRealityETH irl = IRealityETH(irlAddr);

        RealRulebook rr = new RealRulebook(address(ss), irlAddr);
        ss.setRules(address(rr), false);

        // register
        bytes32 salt = hex"abc123";
        bytes32 pr = keccak256(abi.encodePacked(uint256(123), salt));

        bytes32 q0 = ss.preRegistration(pr, "black", "XL", unicode"🧦");
        irl.submitAnswer{value:1}(q0, YES, 0);

        vm.warp(block.timestamp + 60);
        ss.revealRegistration(123, salt, pr);

        // mint
        uint mintReq = ss.initMint(address(42), 123, 11);
        bytes32 q1 = rr.getQuestionId(RealRulebook.QuestionType.Mint, mintReq, 0);
        irl.submitAnswer{value:1}(q1, YES, 0);

        vm.warp(block.timestamp + 60);
        assertEq(uint(irl.resultFor(q1)), 1);

        ss.completeMint(mintReq, address(42), 123, 11);
        assertEq(ss.balanceOf(address(42), 123), 11);

        // redeem
        vm.prank(address(42));
        ss.setOperator(address(this), true);

        uint redeemReq = ss.initRedemption(address(42), 123, 1);
        bytes32 q2 = rr.getQuestionId(RealRulebook.QuestionType.Redeem, redeemReq, 0);
        irl.submitAnswer{value:1}(q2, YES, 0);

        vm.warp(block.timestamp + 60);
        assertEq(uint(irl.resultFor(q2)), 1);

        vm.prank(address(1337)); // anyone
        ss.completeRedemption(redeemReq, address(42), 123, 1);
        assertEq(ss.balanceOf(address(42), 123), 10);

        // audit
        vm.expectRevert();
        rr.requestAudit(456);
        uint auditReq = rr.requestAudit(123);

        bytes32 q3 = rr.getQuestionId(RealRulebook.QuestionType.Audit, auditReq, 123);
        irl.submitAnswer{value:1}(q3, bytes32(uint(555)), 0);

        vm.warp(block.timestamp + 300);
        rr.finalizeAudit(123, auditReq);
        assertEq(rr.balances(123), 555);

        // auditoor role check
        vm.prank(address(3));
        vm.expectRevert();
        rr.requestAudit(123);

        rr.grantRoles(address(3), 1);
        vm.prank(address(3));
        rr.requestAudit(123);
    }
}
