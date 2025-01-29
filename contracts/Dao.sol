// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Dao {
    struct Proposal {
        string description;
        uint256 voteCount;
        uint256 deadline;
        bool executed;
    }

    address public owner;
    uint256 public proposalCount;
    mapping(uint256 => Proposal) public proposals;
    mapping(uint256 => mapping(address => bool)) public votes;
    mapping(address => uint256) public shares;
    uint256 public totalShares;
    event ProposalCreated(uint256 id, string description, uint256 deadline);
    event Voted(uint256 proposalId, address voter);
    event ProposalExecuted(uint256 proposalId);

    constructor() {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can send this message");
        _;
    }

    modifier onlyShareHolder() {
        require(shares[msg.sender] > 0, "Only ShareHolder can participate");
        _;
    }

    modifier activeProposals(uint256 proposalId) {
        require(
            block.timestamp < proposals[proposalId].deadline,
            "The proposal is executed"
        );
        require(!proposals[proposalId].executed, "The proposal is expired");
        _;
    }

    function issueShares(address to, uint256 amount) public onlyOwner {
        require(amount > 0, "Amount should be greater than 0");
        shares[to] += amount;
        totalShares += amount;
    }

    function createProposals(string memory description, uint256 votingperiod)
        external
        onlyShareHolder
    {
        require(bytes(description).length > 0, "Desription cannot be empty");
        require(votingperiod > 0, "Enter valid voting period");
        proposalCount++;
        proposals[proposalCount] = Proposal({
            description: description,
            voteCount: 0,
            deadline: block.timestamp + votingperiod,
            executed: false
        });
        emit ProposalCreated(
            proposalCount,
            description,
            block.timestamp + votingperiod
        );
    }

    function vote(uint256 proposalId)
        external
        onlyShareHolder
        activeProposals(proposalId)
    {
        require(!votes[proposalId][msg.sender], "You have already voted");
        Proposal storage proposal = proposals[proposalId];
        proposal.voteCount += shares[msg.sender];
        votes[proposalId][msg.sender] = true;
        emit Voted(proposalId, msg.sender);
    }

    function executeProposal(uint256 ProposalId) external onlyShareHolder {
        Proposal storage proposal = proposals[ProposalId];
        require(
            block.timestamp >= proposal.deadline,
            "Proposal is not expired"
        );
        require(!proposal.executed, "Proposal is already executed");
        uint256 quorum = totalShares / 2;
        require(proposal.voteCount > quorum, "Not enough votes to execute");
        proposal.executed = true;
        emit ProposalExecuted(ProposalId);
    }

    function getProposal(uint256 ProposalId)
        external
        view
        returns (
            string memory description,
            uint256 voteCount,
            uint256 deadline,
            bool executed
        )
    {
        Proposal storage proposal = proposals[ProposalId];
        return (
            proposal.description,
            proposal.voteCount,
            proposal.deadline,
            proposal.executed
        );
    }
}
