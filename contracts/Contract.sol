// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract UserManagedNFTNew is ERC721, AccessControl {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    bytes32 public constant VERIFIED_USER_ROLE =
        keccak256("VERIFIED_USER_ROLE");

    mapping(uint256 => string) private tokenIPFSHashes;
    mapping(uint256 => string) private tokenTitles; // New mapping for token titles
    mapping(uint256 => address) private tokenMinters;
    mapping(uint256 => mapping(address => bool)) private accessPermissions;

    constructor() ERC721("UserManagedNFT", "UMNFT") {
        // Start token IDs from 1 instead of 0
        _tokenIds.increment();
    }

    function nextTokenIdToMint() public view returns (uint256) {
        return _tokenIds.current();
    }

    function mintNFT(
        address to,
        string memory ipfsHash,
        string memory title // Accept title as a parameter
    ) external returns (uint256) {
        uint256 newTokenId = _tokenIds.current();
        _tokenIds.increment();

        _mint(to, newTokenId);
        tokenIPFSHashes[newTokenId] = ipfsHash;
        tokenTitles[newTokenId] = title; // Store the title
        tokenMinters[newTokenId] = msg.sender;
        accessPermissions[newTokenId][to] = true; // Minter has initial access

        return newTokenId;
    }

    function getIPFSHash(
        uint256 tokenId,
        address caller
    ) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");

        bool hasAccessPermission = accessPermissions[tokenId][caller];
        address owner = ownerOf(tokenId);
        address minter = tokenMinters[tokenId];

        // Check if the caller is the minter, owner, or has been granted access
        require(
            hasAccessPermission || owner == caller || minter == caller,
            string(
                abi.encodePacked(
                    "Access restricted: caller is not authorized. ",
                    "Caller: ",
                    Strings.toHexString(uint160(caller), 20),
                    ", Minter: ",
                    Strings.toHexString(uint160(minter), 20),
                    ", Owner: ",
                    Strings.toHexString(uint160(owner), 20),
                    ", Permission: ",
                    hasAccessPermission ? "true" : "false"
                )
            )
        );

        return tokenIPFSHashes[tokenId];
    }

    function getTokenTitle(
        uint256 tokenId
    ) external view returns (string memory) {
        require(_exists(tokenId), "Token does not exist");
        return tokenTitles[tokenId]; // Return the title
    }

    // Helper function to check if an IPFS hash is stored for a specific token
    function checkStoredIPFSHash(
        uint256 tokenId
    ) external view returns (string memory) {
        return tokenIPFSHashes[tokenId];
    }

    // Helper function to verify access permissions for a specific user and token ID
    function checkAccessPermission(
        uint256 tokenId,
        address user
    ) external view returns (bool) {
        return accessPermissions[tokenId][user];
    }

    // Override supportsInterface to resolve conflict
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override(ERC721, AccessControl) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Check who the minter of the token is
    function checkMinter(uint256 tokenId) external view returns (address) {
        return tokenMinters[tokenId];
    }

    function getIPFSHashNoAccessControl(
        uint256 tokenId
    ) external view returns (string memory) {
        // Comment out access control temporarily for testing
        require(_exists(tokenId), "Token does not exist");

        // Return the IPFS hash directly to see if it resolves
        return tokenIPFSHashes[tokenId];
    }
}
