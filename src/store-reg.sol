// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/delegatable-sol/contracts/Delegatable.sol";


contract Store is ERC721Enumerable, Delegatable {
    string public baseURI;
    mapping(uint256 => bytes32) public storeRootHash;
    mapping(uint256 => string[]) public relays;
    

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) Delegatable("ShopReg", "1") {
        baseURI = _baseURI;
    }

    function mintTo(address recipient, uint256 id, bytes32 rootHash) public returns (uint256) {
        // safe mint checks id
        _safeMint(recipient, id);
        // update the hash
        storeRootHash[id] = rootHash;
        return id;
    }

    function updateRootHash(uint256 id, bytes32 hash) public
    {
        address owner = _ownerOf(id);
        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender) ||
            msg.sender == getApproved(id),
            "NOT_AUTHORIZED"
        );
        storeRootHash[id] = hash;
    }

    function updateRelays(uint256 id, string[] memory _relays) public {
        address owner = _ownerOf(id);
        require(
            msg.sender == owner ||
            isApprovedForAll(owner, msg.sender) ||
            msg.sender == getApproved(id),
            "NOT_AUTHORIZED"
        );
        relays[id] = _relays;  
    }

    function _msgSender()
        internal
        view
        virtual
        override(DelegatableCore, Context)
        returns (address sender)
    {
        if (msg.sender == address(this)) {
            bytes memory array = msg.data;
            uint256 index = msg.data.length;
            assembly {
                sender := and(
                    mload(add(array, index)),
                    0xffffffffffffffffffffffffffffffffffffffff
                )
            }
        } else {
            sender = msg.sender;
        }
        return sender;
    }
}
