// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.21;

import "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "delegatable-sol/contracts/Delegatable.sol";


contract Store is ERC721Enumerable {
    string public baseURI;
    mapping(uint256 => bytes32) public storeRootHash;

    constructor(
        string memory _name,
        string memory _symbol,
        string memory _baseURI
    ) ERC721(_name, _symbol) {
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
}
