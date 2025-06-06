// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @dev Interface for the FakeNFTMarketplace
 */
interface IFakeNFTMarketplace {
    /**
     * @dev getNftPrice() returns the price of an NFT from the FakeNFTMarketplace
     * @return Returns the price in Wei for an NFT
     */
    function getNftPrice() external view returns (uint256);

    /**
     * @dev isAvailable() checks if the given tokenId has an owner address
     * @param _tokenId - the fake NFT token Id to check the owner of
     * @return bool - true if the tokenId has no owner address
     */
    function isAvailable(uint256 _tokenId) external view returns (bool);

    /**
     * @dev purchaseToken() allows the user to purchase a NFT from the FakeNFTMarketplace
     * @param _tokenId - the fake NFT token Id to purchase
     */
    function purchaseToken(uint256 _tokenId) external payable;
}

/**
 * @dev Interface for the CryptoDevsNFT
 */
interface ICryptoDevsNFT {
    /**
     * @dev balanceOf() returns the number of NFTs owned by the given address
     * @param _owner - the address to check the balance of
     * @return Returns the number of NFTs owned by the given address
     */
    function balanceOf(address _owner) external view returns (uint256);

    /**
     * @dev tokenOfOwnerByIndex() returns a token ID at a given index for a given owner
     * @param _owner - the address to check the balance of
     * @param _index - the index to check the balance of
     * @return Returns the token ID at the given index for the given owner
     */
    function tokenOfOwnerByIndex(address _owner, uint256 _index) external view returns (uint256);
}

/**
 * @dev Enum to represent the vote of a voter
 */
enum Vote {
    YES, // YES = vote to accept the proposal
    NO // NO = vote to reject the proposal
}

/**
 * @dev Proposal struct to store proposal information
 */
struct Proposal {
    uint256 nftTokenId; // the tokenID of the NFT to purchase from FakeNFTMarketplace if the proposal passes
    uint256 deadline; // the deadline for the proposal
    uint256 yesVotes; // number of yes votes for the proposal
    uint256 noVotes; // number of no votes for the proposal
    bool executed; // whether the proposal has been executed
    mapping(uint256 => bool) voters; // mapping of token IDs to booleans indicating if they have voted on the proposal
}

/**
 * @dev CryptoDevsDAO is a contract for the CryptoDevsDAO
 */
contract CryptoDevsDAO is Ownable {
    mapping(uint256 => Proposal) public proposals; // the mapping for storing the proposals
    uint256 public totalProposals; // the total number of proposals

    IFakeNFTMarketplace fakeNFTMarketplace; // the FakeNFTMarketplace contract instance
    ICryptoDevsNFT cryptoDevsNFT; // the CryptoDevsNFT contract instance

    /**
     * @dev constructor to initialize the contract
     * @param _fakeNFTMarketplace - the address of the FakeNFTMarketplace contract
     * @param _cryptoDevsNFT - the address of the CryptoDevsNFT contract
     */
    constructor(address _fakeNFTMarketplace, address _cryptoDevsNFT) Ownable(msg.sender) {
        fakeNFTMarketplace = IFakeNFTMarketplace(_fakeNFTMarketplace);
        cryptoDevsNFT = ICryptoDevsNFT(_cryptoDevsNFT);
    }

    /**
     * @dev modifier to check if the caller is a DAO member by owning at least 1 CrytoDevsNFT
     */
    modifier nftHolderOnly() {
        require(cryptoDevsNFT.balanceOf(msg.sender) > 0, "NOT_A_DAO_MEMBER");
        _;
    }

    /**
     * @dev modifier to check if the proposal is still active (not past deadline)
     */
    modifier activeProposalOnly(uint256 _proposalId) {
        require(proposals[_proposalId].deadline > block.timestamp, "DEADLINE_EXPIRED");
        _;
    }

    /**
     * @dev modifier to check if the proposal is inactive (past deadline) and not executed
     */
    modifier inactiveProposalsOnly(uint256 _proposalId) {
        require(proposals[_proposalId].deadline <= block.timestamp, "PROPOSAL_NOT_INACTIVE");
        require(proposals[_proposalId].executed == false, "PROPOSAL_ALREADY_EXECUTED");
        _;
    }

    /**
     * @dev createProposal() creates a new proposal for a given NFT token ID
     * @param _nftTokenId - the NFT token ID to create a proposal for
     * @return the ID of the newly created proposal
     */
    function createProposal(uint256 _nftTokenId) external nftHolderOnly returns (uint256) {
        require(fakeNFTMarketplace.isAvailable(_nftTokenId), "NFT_NOT_FOR_SALE");
        Proposal storage proposal = proposals[totalProposals];
        proposal.deadline = block.timestamp + 5 minutes;
        totalProposals++;

        return totalProposals - 1;
    }

    /**
     * @dev voteOnProposal() allows a voter to vote on a proposal
     * @param _proposalId - the ID of the proposal to vote on
     * @param _vote - the vote to cast (YES or NO)
     */
    function voteOnProposal(uint256 _proposalId, Vote _vote) external nftHolderOnly activeProposalOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        uint256 voterNFTBalance = cryptoDevsNFT.balanceOf(msg.sender);
        uint256 numVotes = 0;

        // Calculate how many NFTs are owned by the voter that haven't already been used for voting on this proposal
        for (uint256 i = 0; i < voterNFTBalance; i++) {
            uint256 tokenId = cryptoDevsNFT.tokenOfOwnerByIndex(msg.sender, i);

            if (proposal.voters[tokenId] == false) {
                numVotes++;
                proposal.voters[tokenId] = true; // Mark this NFT as having voted
            }
        }

        require(numVotes > 0, "ALREADY_VOTED");

        // Add the votes based on the number of NFTs
        if (_vote == Vote.YES) {
            proposal.yesVotes += numVotes;
        } else {
            proposal.noVotes += numVotes;
        }
    }

    /**
     * @dev executeProposal() executes a proposal if it has more YES votes than NO votes
     * @param _proposalId - the ID of the proposal to execute
     */
    function executeProposal(uint256 _proposalId) external nftHolderOnly inactiveProposalsOnly(_proposalId) {
        Proposal storage proposal = proposals[_proposalId];
        
        if (proposal.yesVotes > proposal.noVotes) {
            uint256 nftPrice = fakeNFTMarketplace.getNftPrice();
            require(address(this).balance >= nftPrice, "NOT_ENOUGH_FUNDS");
            fakeNFTMarketplace.purchaseToken{value: nftPrice}(proposal.nftTokenId);
        }

        proposal.executed = true;
    }

    /**
     * @dev withdrawEther() allows the owner to withdraw the ETH from the contract
     */
    function withdrawEther() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "NO_FUNDS_TO_WITHDRAW");

        (bool sent, ) = payable(owner()).call{value: amount}("");
        require(sent, "FAILED_TO_WITHDRAW_ETHER");
    }

    /**
     * @dev receive function to allow the contract to receive ETH
     */
    receive() external payable {}

    /**
     * @dev fallback function to allow the contract to receive ETH
     */
    fallback() external payable {}
}