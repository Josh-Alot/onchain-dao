// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

contract FakeNFTMarket {
    /// @dev Maintain a mapping of Fake TokenID to Owner addresses
    mapping(uint256 => address) public tokens;

     /// @dev Set the purchase price for each Fake NFT
    uint256 nftPrice = 0.01 ether;

    /**
     * @dev purchase() accepts ETH and marks the owner of the given tokenId as the caller address
     * @param _tokenId - the fake NFT token Id to purchase
     */
    function purchaseToken(uint256 _tokenId) external payable {
        require(msg.value == nftPrice, "This NFT costs 0.01 ether");
        tokens[_tokenId] = msg.sender;
    }

    /// @dev getPrice() returns the price of a NFT
    function getNftPrice() external view returns (uint256) {
        return nftPrice;
    }

    /**
     * @dev isAvailable() checks if the given tokenId has an owner address
     * @param _tokenId - the fake NFT token Id to check the owner of
     * @return bool - true if the tokenId has no owner address
     */
    function isAvailable(uint256 _tokenId) external view returns (bool) {
        if (tokens[_tokenId] == address(0)) {
            return true;
        }
        
        return false;
    }
}