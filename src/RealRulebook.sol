// SPDX-License-Identifier: MIT+RTL
pragma solidity ^0.8.21;
import "./interfaces.sol";
import "solady/src/auth/OwnableRoles.sol";
import "solady/src/utils/LibString.sol";

contract RealRulebook is IRulebook, IRlRules, OwnableRoles {
    // oracle needed
    enum QuestionType {
        Registration,
        Mint,
        Redeem,
        Audit
    }
    struct PreView {
        address whom;
        uint256 id;
        uint256 amount;
        bytes32 questionId;
    }

    uint32 public timeout = 60;
    address immutable daSwap;
    IRealityETH public reality;
    uint256[4] public templateIds;

    mapping(bytes32 => bytes32) commitedEvidence;
    mapping(uint256 => bytes32) public registry;

    PreView[] public preMints;
    PreView[] public preRedeems;

    mapping(uint256 => uint256) public balances;
    mapping(uint256 => bytes32[]) public audits;
    uint256 public constant AUDITOOR = 1; // role

    constructor(address parent, address reality_eth) {
        _initializeOwner(msg.sender);
        daSwap = parent;
        reality = IRealityETH(reality_eth);

        // QuestionType.Registration
        templateIds[0] = reality.createTemplate(
            '{"title": "Is %s a picture of real socks the type of which has not been registered by SockSwap before? The supposed type of socks: %s (size %s).", "type": "bool", "category": "arts", "lang": "en_US"}'
        );
        // QuestionType.Mint
        templateIds[1] = reality.createTemplate(
            '{"title": "Will mint request #%s result in the number of *unworn* pairs of socks (token id %s) in the box to increase by %s?", "type": "bool", "category": "arts", "lang": "en_US"}'
        );
        // QuestionType.Redeem
        templateIds[2] = reality.createTemplate(
            '{"title": "Will redemption request #%s result in the number of pairs of socks (token id %s) in the box to decrease by %s?", "type": "bool", "category": "arts", "lang": "en_US"}'
        );
        // QuestionType.Audit
        templateIds[3] = reality.createTemplate(
            '{"title": "How many pairs of socks that match token id %s are there in the box?", "type": "uint", "decimals": 0, "category": "arts", "lang": "en_US"}'
        );
    }

    modifier onlySockSwap() {
        require(msg.sender == daSwap);
        _;
    }

    function getQuestionId(
        QuestionType qt,
        uint256 loc,
        uint256 id
    ) public view returns (bytes32) {
        if (qt == QuestionType.Mint) {
            return preMints[loc].questionId;
        } else if (qt == QuestionType.Redeem) {
            return preRedeems[loc].questionId;
        } else if (qt == QuestionType.Audit) {
            return audits[id][loc];
        }
        return commitedEvidence[bytes32(loc)];
    }

    function check(uint256 id) external view returns (bool) {
        bytes32 qId = registry[id];
        if (uint256(qId) == 0) {
            return false;
        }
        bytes32 res = reality.resultFor(qId);
        return uint256(res) == 1;
    }

    function exists(uint256 id, uint256 amount) external view returns (bool) {
        return balances[id] >= amount;
    }

    function prereg(bytes32 commit) external onlySockSwap returns (bytes32) {
        SockSnap memory pending = ISockSwap(daSwap)._readCommit(commit);
        bytes32 questionId = reality.askQuestion(
            templateIds[0],
            string(
                abi.encodePacked(
                    pending.photo,
                    unicode"␟",
                    pending.category,
                    unicode"␟",
                    pending.size
                )
            ),
            address(0),
            timeout,
            uint32(block.timestamp),
            0
        );
        commitedEvidence[commit] = questionId;
        return questionId;
    }

    function reveal(
        uint256 id,
        bytes32 salt,
        bytes32 commit
    ) external onlySockSwap {
        require(commit == keccak256(abi.encodePacked(id, salt))); // double triple check
        bytes32 qId = commitedEvidence[commit];
        require(uint256(reality.resultFor(qId)) == 1);
        registry[id] = commitedEvidence[commit];
        delete commitedEvidence[commit];
    }

    function premint(
        address to,
        uint256 id,
        uint256 amount
    ) external onlySockSwap returns (uint256) {
        require(ISockSwap(daSwap)._regCheck(id));
        uint256 reqId = preMints.length;
        bytes32 questionId = reality.askQuestion(
            templateIds[1],
            string(
                abi.encodePacked(
                    LibString.toString(reqId),
                    unicode"␟",
                    LibString.toString(id),
                    unicode"␟",
                    LibString.toString(amount)
                )
            ),
            address(0),
            timeout,
            uint32(block.timestamp),
            0
        );
        preMints.push(PreView(to, id, amount, questionId));

        return reqId;
    }

    function print(
        uint256 reqId,
        address to,
        uint256 id,
        uint256 amount
    ) external onlySockSwap returns (bool) {
        PreView storage req = preMints[reqId];
        if (uint256(req.questionId) == 0) return false;
        require(uint256(reality.resultFor(req.questionId)) == 1);
        require(req.whom == to && req.id == id && req.amount == amount);
        balances[req.id] += req.amount;
        return true;
    }

    function preredeem(
        address from,
        uint256 id,
        uint256 amount
    ) external onlySockSwap returns (uint256) {
        // require(amount > 0 && this.exists(id, amount)); // checked by SockSwap
        uint256 reqId = preRedeems.length;
        bytes32 questionId = reality.askQuestion(
            templateIds[2],
            string(
                abi.encodePacked(
                    LibString.toString(reqId),
                    unicode"␟",
                    LibString.toString(id),
                    unicode"␟",
                    LibString.toString(amount)
                )
            ),
            address(0),
            timeout,
            uint32(block.timestamp),
            0
        );
        preRedeems.push(PreView(from, id, amount, questionId));

        return reqId;
    }

    function redeem(
        uint256 reqId,
        address from,
        uint256 id,
        uint256 amount
    ) external onlySockSwap returns (bool) {
        PreView storage req = preRedeems[reqId];
        if (uint256(req.questionId) == 0) return false;
        require(uint256(reality.resultFor(req.questionId)) == 1);
        require(req.whom == from && req.id == id && req.amount == amount);
        balances[req.id] -= req.amount;
        return true;
    }

    function requestAudit(
        uint256 tokenId
    ) public onlyOwnerOrRoles(AUDITOOR) returns (uint256) {
        require(this.exists(tokenId, 1), "nothing to check");
        uint256 reqId = audits[tokenId].length;
        bytes32 questionId = reality.askQuestion(
            templateIds[3],
            LibString.toString(tokenId),
            address(0),
            5 * timeout,
            uint32(block.timestamp),
            0
        );
        audits[tokenId].push(questionId);

        return reqId;
    }

    function finalizeAudit(
        uint256 tokenId,
        uint256 auditId
    ) public returns (bool) {
        bytes32 questionId = audits[tokenId][auditId];
        if (uint256(questionId) == 0) return false;
        uint256 result = uint256(reality.resultFor(questionId));
        if (result == type(uint256).max) return false; // invalid
        balances[tokenId] = result;
        audits[tokenId][auditId] = 0; // apply only once
        return true;
    }
}
