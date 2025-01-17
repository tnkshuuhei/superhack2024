// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract AttestationERC721 is Initializable, ERC721Upgradeable, AccessControlUpgradeable {
    error CannnotHoldMoreThanOneAttestationERC721(address owner);

    using Strings for uint256;

    uint256 private _nextTokenId;
    string private _defaultImageUrl;

    string public description;

    struct TokenData {
        address owner;
        string description;
        string imageUrl;
    }

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(uint256 => TokenData) public _tokenData;

    mapping(uint256 => address[]) public previousOwners;

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize(address initialOwner, string memory _description, string memory defaultImageUrl)
        public
        initializer
    {
        __ERC721_init("AttestationERC721", "ATT");
        __AccessControl_init();

        _defaultImageUrl = defaultImageUrl;
        description = _description;
        _grantRole(DEFAULT_ADMIN_ROLE, initialOwner);
        _grantRole(MINTER_ROLE, initialOwner);
    }

    function setDefaultImageUrl(string memory defaultImageUrl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _defaultImageUrl = defaultImageUrl;
    }

    function setImageURL(uint256 tokenId, string memory imageUrl) external onlyRole(DEFAULT_ADMIN_ROLE) {
        _tokenData[tokenId].imageUrl = imageUrl;
    }

    /// @notice Mint a new NFT to the given address
    /// @dev The caller must have the MINTER_ROLE. If 'imageUrl' is empty,
    /// the default image URL will be used when tokenURI() is called, and store empty string in the tokenData mapping.
    /// @dev Each address can hold only one Token, if the address already holds a token, it will be reverted.
    /// @param to The address to mint the NFT to
    /// @param imageUrl The URL of the image to be displayed
    /// @return The TokenData struct of the minted token
    function safeMint(address to, string memory imageUrl) external onlyRole(MINTER_ROLE) returns (TokenData memory) {
        // revert if the address already holds a token
        if (balanceOf(to) > 0) {
            revert CannnotHoldMoreThanOneAttestationERC721(to);
        }

        // increment the next token ID
        uint256 tokenId = _nextTokenId++;

        // create a new TokenData struct and store it in the mapping
        TokenData memory newTokenData = TokenData({owner: to, description: description, imageUrl: imageUrl});
        _tokenData[tokenId] = newTokenData;

        // mint the token
        _safeMint(to, tokenId);

        // return the TokenData struct
        return newTokenData;
    }

    function setMinter(address _minter) public onlyRole(DEFAULT_ADMIN_ROLE) {
        grantRole(MINTER_ROLE, _minter);
    }

    function getOwners(uint256 tokenId) public view returns (address[] memory) {
        return previousOwners[tokenId];
    }

    function getTokenData(uint256 tokenId) public view returns (TokenData memory) {
        return _tokenData[tokenId];
    }

    // The following functions are overrides required by Solidity.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721Upgradeable)
        returns (address)
    {
        previousOwners[tokenId].push(to);
        _tokenData[tokenId].owner = to;
        return super._update(to, tokenId, auth);
    }

    /// @notice Returns the token URI for the given token ID
    /// @dev The token URI is generated using the token ID and the tokenData mapping.
    /// @dev attributes and metadata is optimized for OpenSea
    /// @param tokenId The token ID
    /// @return The token URI
    function tokenURI(uint256 tokenId) public view override(ERC721Upgradeable) returns (string memory) {
        TokenData memory tokenData = _tokenData[tokenId];

        bytes memory attributes = abi.encodePacked(
            '{"trait_type": "ID", "value": "',
            tokenId.toString(),
            '"},',
            '{"trait_type": "name", "value": "',
            "AttestationERC721",
            '"}'
        );

        string memory imageUrl = bytes(tokenData.imageUrl).length > 0 ? tokenData.imageUrl : _defaultImageUrl;

        bytes memory metadata = abi.encodePacked(
            '{"name": "AttestationERC721 2024 #',
            tokenId.toString(),
            '", "description": "',
            tokenData.description,
            '", "image": "',
            imageUrl,
            '", "attributes": [',
            attributes,
            "]}"
        );
        return string(abi.encodePacked("data:application/json;base64,", Base64.encode(metadata)));
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, AccessControlUpgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
