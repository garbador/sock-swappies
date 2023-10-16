// SPDX-License-Identifier: MIT+RTL

pragma solidity ^0.8.21;

struct SockSnap {
    string category; // describe what kind of sock it is in 1 or 2 words
    string photo; // 📸 yep, this one's going in my cringe compilation
    string size; // .. what size foot does it fit
}

interface ISockSwap {
    function _regCheck(uint256 id) external view returns (bool registered);

    function _readCommit(
        bytes32 commit
    ) external view returns (SockSnap memory);
}

interface IRulebook {
    // how long until a question is finalized
    function timeout() external view returns (uint32);

    // is this an un/identified sock
    function check(uint256 id) external view returns (bool valid);

    // there exist this many pairs of a pre-identified sock
    function exists(
        uint256 id,
        uint256 amount
    ) external view returns (bool valid);
}

// only SockSwap should be able to call these..
interface IRlRules {
    function prereg(bytes32 commit) external returns (bytes32);

    // is this a unique & fresh pair of socks
    function reveal(uint256 id, bytes32 salt, bytes32 commit) external;

    function premint(
        address to,
        uint256 id,
        uint256 amount
    ) external returns (uint256 reqId);

    // are these the socks you claim they are
    function print(
        uint256 reqId,
        address to,
        uint256 id,
        uint256 amount
    ) external returns (bool);

    function preredeem(
        address from,
        uint256 id,
        uint256 amount
    ) external returns (uint256 reqId);

    // did you get your socks
    function redeem(
        uint256 reqId,
        address from,
        uint256 id,
        uint256 amount
    ) external returns (bool);
}

interface IRealityETH {
    function askQuestion(
        uint256 template_id,
        string memory question,
        address arbitrator,
        uint32 timeout,
        uint32 opening_ts,
        uint256 nonce
    ) external payable returns (bytes32);

    function submitAnswer(
        bytes32 question_id,
        bytes32 answer,
        uint256 max_previous
    ) external payable;

    function createTemplate(string memory content) external returns (uint256);

    function templates(uint256) external view returns (uint256);

    function resultFor(bytes32 question_id) external view returns (bytes32);
}
