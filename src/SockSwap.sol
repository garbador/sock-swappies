// SPDX-License-Identifier: MIT
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

    struct SockSnap {
        string category; // describe what kind of sock it is in 1 or 2 words
        string photo; // 📸 yep, this one's going in my cringe compilation
        string size; // .. what size foot does it fit
    }

    IRulebook public rules;
    mapping(uint256 => SockSnap) public registry;

    constructor() {
        _initializeOwner(msg.sender);
        // starting rules
        rules = new CarteBlanche(address(this));
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
        string memory n = rules.check(id)
            ? LibString.concat(registry[id].category, " socks")
            : "not a sock";
        return
            string(
                abi.encodePacked(
                    '{"name":"',
                    n,
                    '", "image":"',
                    registry[id].photo,
                    '", "attributes": [{ "trait_type": "size", "value": ',
                    registry[id].size,
                    "}]}"
                )
            );
    }

    function setRules(address _rules) public onlyOwner {
        rules = IRulebook(_rules);
    }

    function register(
        uint256 id,
        string memory category,
        string memory size,
        string memory photo
    ) public {
        require(totalSupply(id) == 0);
        SockSnap storage new_socks = registry[id];
        new_socks.category = LibString.escapeJSON(category, true);
        new_socks.size = size;
        new_socks.photo = photo;
        require(_charCount(id) > 3, "definitely not a sock");
        emit NewSockDiscovered(id, msg.sender, photo);
    }

    function _charCount(uint256 id) private view returns (uint256) {
        SockSnap memory to_check = registry[id];
        return
            LibString.runeCount(to_check.category) +
            LibString.runeCount(to_check.photo) +
            LibString.runeCount(to_check.size);
    }

    function _regCheck(uint256 id) external view returns (bool) {
        return _charCount(id) > 0;
    }

    // init
    function mint(address to, uint256 id, uint256 amount) public payable {
        // gotta be registered
        // & u are putting N in
        require(rules.exists(id, amount));
        _mint(to, id, amount);
    }
    // complete

    // init
    function redeem(address from, uint256 id, uint256 amount) public {
        require(
            isOperator(from, msg.sender) ||
                allowance(from, msg.sender, id) >= amount
        );
        require(rules.exists(id, amount));
        _burn(from, id, amount);
    }
    // complete
}
