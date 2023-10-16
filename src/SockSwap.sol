// SPDX-License-Identifier: MIT+RTL
pragma solidity ^0.8.21;
import "./interfaces.sol";
import "./Rulebook.sol";
import "solady/src/auth/Ownable.sol";
import "solady/src/tokens/ERC6909.sol";
import "solady/src/utils/LibString.sol";

contract SockSwap is Ownable, ERC6909, ISockSwap {
    error TokenDoesNotExist();
    event NewSockDiscovered(
        uint256 indexed id,
        address indexed researcher,
        string pic
    );
    event MintRequested(
        uint256 indexed reqId,
        address indexed toWhom,
        uint256 tokenId,
        uint256 amount
    );
    event RedemptionRequested(
        uint256 indexed reqId,
        address indexed byWhom,
        uint256 tokenId,
        uint256 amount
    );

    bool public mockSocks;
    IRulebook public rules;
    IRlRules public irlRules;

    mapping(bytes32 => SockSnap) commits;
    mapping(uint256 => SockSnap) public registry;

    constructor() {
        _initializeOwner(msg.sender);
        // starting rules
        mockSocks = true;
        rules = new CarteBlanche(address(this));
    }

    modifier whenMock() {
        require(mockSocks);
        _;
    }

    modifier whenIrl() {
        require(!mockSocks);
        _;
    }

    function name() public view virtual override returns (string memory) {
        return "SockSwap";
    }

    function symbol() public view virtual override returns (string memory) {
        return unicode"⚡🧦";
    }

    function tokenURI(
        uint256 id
    ) public view virtual override returns (string memory) {
        if (totalSupply(id) == 0) revert TokenDoesNotExist();
        string memory n = (mockSocks || rules.check(id))
            ? string(
                abi.encodePacked(
                    registry[id].category,
                    unicode" socks (№",
                    LibString.toString(id),
                    ")"
                )
            )
            : "not a sock";
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    n,
                    '", "image":"',
                    registry[id].photo,
                    '", "attributes": [{ "trait_type": "size", "value": "',
                    registry[id].size,
                    '"}]}'
                )
            );
    }

    function setRules(address _rules, bool _mockOrNot) public onlyOwner {
        rules = IRulebook(_rules);
        irlRules = _mockOrNot ? IRlRules(address(0)) : IRlRules(_rules);
        mockSocks = _mockOrNot;
    }

    function _commit(
        bytes32 _preReg,
        string memory category,
        string memory size,
        string memory photo
    ) private {
        SockSnap storage new_socks = commits[_preReg];
        new_socks.category = LibString.escapeJSON(category, true);
        new_socks.size = size;
        new_socks.photo = photo;
        require(_charCount(_preReg) > 3, "definitely not a sock");
    }

    function commit(
        bytes32 _preReg,
        string memory category,
        string memory size,
        string memory photo
    ) public whenMock {
        _commit(_preReg, category, size, photo);
    }

    function preRegistration(
        bytes32 _preReg,
        string memory category,
        string memory size,
        string memory photo
    ) public whenIrl returns (bytes32) {
        _commit(_preReg, category, size, photo);
        return irlRules.prereg(_preReg);
    }

    function _reveal(uint256 id, bytes32 salt, bytes32 _preReg) private {
        require(totalSupply(id) == 0);
        require(_charCount(_preReg) > 0);
        require(_preReg == keccak256(abi.encodePacked(id, salt)));
        registry[id] = commits[_preReg];
        delete commits[_preReg];
        emit NewSockDiscovered(id, msg.sender, registry[id].photo);
    }

    function register(
        uint256 id,
        bytes32 salt,
        bytes32 _preReg
    ) public whenMock {
        _reveal(id, salt, _preReg);
    }

    function revealRegistration(
        uint256 id,
        bytes32 salt,
        bytes32 _preReg
    ) public whenIrl {
        irlRules.reveal(id, salt, _preReg);
        require(rules.check(id));
        _reveal(id, salt, _preReg);
    }

    function _charCount(bytes32 _preReg) private view returns (uint256) {
        SockSnap memory to_check = commits[_preReg];
        return
            bytes(to_check.category).length +
            bytes(to_check.photo).length +
            bytes(to_check.size).length;
    }

    function _charCount(uint256 id) private view returns (uint256) {
        SockSnap memory to_check = registry[id];
        return
            bytes(to_check.category).length +
            bytes(to_check.photo).length +
            bytes(to_check.size).length;
    }

    function _regCheck(uint256 id) external view returns (bool) {
        return _charCount(id) > 0;
    }

    function _readCommit(
        bytes32 _preReg
    ) external view returns (SockSnap memory) {
        return commits[_preReg];
    }

    function mint(
        address to,
        uint256 id,
        uint256 amount
    ) public payable whenMock {
        // gotta be registered
        // & u are putting N in
        require(rules.exists(id, amount));
        _mint(to, id, amount);
    }

    function initMint(
        address to,
        uint256 id,
        uint256 amount
    ) public payable whenIrl returns (uint256) {
        require(rules.check(id));
        uint256 reqId = irlRules.premint(to, id, amount);
        emit MintRequested(reqId, to, id, amount);
        return reqId;
    }

    function completeMint(
        uint256 reqId,
        address to,
        uint256 id,
        uint256 amount
    ) public whenIrl {
        require(irlRules.print(reqId, to, id, amount));
        _mint(to, id, amount);
    }

    function redeem(address from, uint256 id, uint256 amount) public whenMock {
        require(
            isOperator(from, msg.sender) ||
                allowance(from, msg.sender, id) >= amount
        );
        require(rules.exists(id, amount));
        _burn(from, id, amount);
    }

    function initRedemption(
        address from,
        uint256 id,
        uint256 amount
    ) public payable whenIrl returns (uint256) {
        require(
            isOperator(from, msg.sender) ||
                allowance(from, msg.sender, id) >= amount
        );
        require(rules.exists(id, amount));
        uint256 reqId = irlRules.preredeem(from, id, amount);
        emit RedemptionRequested(reqId, from, id, amount);
        return reqId;
    }

    function completeRedemption(
        uint256 reqId,
        address from,
        uint256 id,
        uint256 amount
    ) public whenIrl {
        require(irlRules.redeem(reqId, from, id, amount));
        require(rules.exists(id, amount));
        _burn(from, id, amount);
    }
}
