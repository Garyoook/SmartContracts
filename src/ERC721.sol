// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./libraries/StringUtils.sol";

contract ERC721 is IERC721Metadata {
    string public _name;
    string public _symbol;
    string public _baseUri;
    IERC20 public _paymentToken;
    uint256 public tokenPrice;
    uint256 public tokenID;
    mapping (uint256 => address) public tokenOwner;
    mapping (uint256 => address) public approved_user_token_map;

    constructor(
        string memory name_,
        string memory symbol_,
        string memory baseUri,
        IERC20 paymentToken,
        uint256 initialTokenPrice
    ) {
        _name = name_;
        _symbol = symbol_;
        _baseUri = baseUri;
        _paymentToken = paymentToken;
        tokenPrice = initialTokenPrice;
        tokenID = 1;
    }

    function mint(address to) external {
        _paymentToken.transferFrom(msg.sender, address(0), tokenPrice);
        emit Transfer(address(0), to, tokenID);
        tokenOwner[tokenID] = to;
        tokenID += 1;
        tokenPrice = tokenPrice * 11/10;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 1; i <= tokenID; i++) {
            if (tokenOwner[i] == _owner) {
                balance += 1;
            }
        }
        return balance;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return tokenOwner[_tokenId];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        tokenOwner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(tokenOwner[_tokenId] == msg.sender, "not authorized");
        approved_user_token_map[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return approved_user_token_map[_tokenId];
    }

    function name() external view returns (string memory) {
        return _name;
    }

    function symbol() external view returns (string memory) {
        return _symbol;
    }

    function tokenURI(uint256 _tokenId) external view returns (string memory) {
        return string.concat(_baseUri, StringUtils.toString(_tokenId));
    }

    // Bonus functions

    function supportsInterface(bytes4 interfaceID)
        external
        view
        returns (bool)
    {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external {}

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {}

    function setApprovalForAll(address _operator, bool _approved) external {}

    function isApprovedForAll(address _owner, address _operator)
        external
        view
        returns (bool)
    {}
}
