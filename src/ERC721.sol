// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "./interfaces/IERC20.sol";
import "./interfaces/IERC721.sol";
import "./libraries/StringUtils.sol";
import "./interfaces/IERC721TokenReceiver.sol";

contract ERC721 is IERC721Metadata {
    string public _name;
    string public _symbol;
    string public _baseUri;
    IERC20 public _paymentToken;
    uint256 public tokenPrice;
    uint256 public tokenID;
    mapping(uint256 => address) public token_to_owner;
    mapping(uint256 => address) public token_to_approvedUser;

    mapping(address => mapping(address => bool)) internal owner_to_operators;

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
        token_to_owner[tokenID] = to;
        tokenID += 1;
        tokenPrice = (tokenPrice * 11) / 10;
    }

    function balanceOf(address _owner) external view returns (uint256) {
        uint256 balance = 0;
        for (uint256 i = 1; i <= tokenID; i++) {
            if (token_to_owner[i] == _owner) {
                balance += 1;
            }
        }
        return balance;
    }

    function ownerOf(uint256 _tokenId) external view returns (address) {
        return token_to_owner[_tokenId];
    }

    function transferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        token_to_owner[_tokenId] = _to;
        emit Transfer(_from, _to, _tokenId);
    }

    function approve(address _approved, uint256 _tokenId) external {
        require(
            token_to_owner[_tokenId] == msg.sender ||
                owner_to_operators[token_to_owner[_tokenId]][msg.sender],
            "not authorized"
        );
        token_to_approvedUser[_tokenId] = _approved;
        emit Approval(msg.sender, _approved, _tokenId);
    }

    function getApproved(uint256 _tokenId) external view returns (address) {
        return token_to_approvedUser[_tokenId];
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

    function supportsInterface(
        bytes4 interfaceID
    ) external view returns (bool) {
        return interfaceID == 0x80ac58cd;
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId,
        bytes memory data
    ) external {
        address tokenOwner = token_to_owner[_tokenId];
        require(
            msg.sender == tokenOwner ||
                msg.sender == token_to_approvedUser[_tokenId] ||
                owner_to_operators[_from][msg.sender],
            "not authorized"
        );
        require(tokenOwner == _from, "not owner");
        require(_to != address(0));

        this.transferFrom(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                data
            );
            require(retval == 0x150b7a02, "magic value not returned");
        }
    }

    function safeTransferFrom(
        address _from,
        address _to,
        uint256 _tokenId
    ) external {
        address tokenOwner = token_to_owner[_tokenId];
        require(
            msg.sender == tokenOwner ||
                msg.sender == token_to_approvedUser[_tokenId] ||
                owner_to_operators[_from][msg.sender],
            "not authorized"
        );
        require(tokenOwner == _from, "not owner");
        require(_to != address(0));
        this.transferFrom(_from, _to, _tokenId);

        if (isContract(_to)) {
            bytes4 retval = IERC721TokenReceiver(_to).onERC721Received(
                msg.sender,
                _from,
                _tokenId,
                ""
            );
            require(retval == 0x150b7a02, "magic value not returned");
        }
    }

    function setApprovalForAll(address _operator, bool _approved) external {
        owner_to_operators[msg.sender][_operator] = _approved;
        emit ApprovalForAll(msg.sender, _operator, _approved);
    }

    function isApprovedForAll(
        address _owner,
        address _operator
    ) external view returns (bool) {
        return owner_to_operators[_owner][_operator];
    }

    function isContract(
        address _addr
    ) internal view returns (bool addressCheck) {
        bytes32 codehash;
        bytes32 accountHash = 0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470;
        assembly {
            codehash := extcodehash(_addr)
        } // solhint-disable-line
        addressCheck = (codehash != 0x0 && codehash != accountHash);
    }
}
