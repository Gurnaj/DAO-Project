// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.2 <0.9.0;

contract DAO
{
    struct Proposal{
        uint id;
        string description;
        uint amount;
        address payable receipient;
        uint votes;
        uint end;
        bool isExecuted;
    }

    mapping(address=>bool) private isInvestor;
    mapping(address=>uint) public numberOfTokens;
    mapping(address=>mapping(uint=>bool)) public isVoted;
    address[] public investorsList;
    mapping(uint=>Proposal) public proposals;

    uint public totalTokens;
    uint public contributionTimeEnd;
    uint public voteTime;
    uint public quorum;
    uint public availableFunds;
    uint public nextProposalId;

    address public manager;

    // uint public gasLimit;

    constructor(uint _contributionTimeEnd, uint _voteTime, uint _quorum){
        require(_quorum>0 && quorum<=100, "Invalid quorum value");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
        voteTime = _voteTime;
        quorum = _quorum;
        manager = msg.sender;
        // gasLimit = block.gaslimit;
    }

    modifier onlyInverstor()
    {
        require(isInvestor[msg.sender] == true, "You are not an investor");
        _;
    }

    modifier onlyManager()
    {
        require(manager == msg.sender, "You are not an investor");
        _;
    }

    function contribution() public payable
    {
        require(block.timestamp <= contributionTimeEnd, "Contribution Time Ended");
        require(msg.value > 0, "Send more than 0 ethers");

        isInvestor[msg.sender] = true;
        investorsList.push(msg.sender);

        numberOfTokens[msg.sender] = msg.value;
        totalTokens += msg.value;

        availableFunds += msg.value;
    }

    function checkInvestorStatus() private
    {
        if(numberOfTokens[msg.sender] == 0)
        {
            isInvestor[msg.sender] = false;
        }
    }

    function redeemTokens(uint amount) public onlyInverstor()
    {
        require(amount <= numberOfTokens[msg.sender], "You don't have enough tokens");
        require(availableFunds >= amount, "Not enough funds available");

        numberOfTokens[msg.sender] -= amount;
        availableFunds -= amount;

        checkInvestorStatus();

        payable(msg.sender).transfer(amount);
    }

    function trasferTokens(uint _amount, address _to) public onlyInverstor()
    {
        require(_amount <= numberOfTokens[msg.sender], "You don't have enough tokens");

        numberOfTokens[msg.sender] -= _amount;

        checkInvestorStatus();

        payable(_to).transfer(_amount);

        if(isInvestor[_to] != true){
            investorsList.push(_to);
        }

        isInvestor[_to] = true;
        numberOfTokens[_to] += _amount;
    }

    function createProposal(string calldata _description , uint _amount, address payable _receipient) public onlyManager()
    {   require(availableFunds >= _amount, "Not sufficient funds to match your amount");

        proposals[nextProposalId] = Proposal(nextProposalId, _description, _amount, _receipient, 0 , block.timestamp + voteTime , false);

        nextProposalId++;
    }

    function voteProposal(uint id) public onlyInverstor()
    {
        Proposal storage proposal = proposals[id];

        require(block.timestamp <= proposal.end, "Voting has been closed for this Proposal");
        require(isVoted[msg.sender][id] == false, "You have already voted on this Proposal");
        require(proposal.isExecuted == false, "This Proposal has already been executed");

        isVoted[msg.sender][id] = true;
        proposal.votes += numberOfTokens[msg.sender];
    }

    function executeProposal(uint id) public view onlyManager()
    {
        Proposal storage proposal = proposals[id];
        
        require(proposal.isExecuted == false, "This Proposal has already been executed");
        require(block.timestamp >= proposal.end, "Voting time for this Proposal hasn't ended yet");
        for(uint i=0; i < nextProposalId; i++){
            require(proposal.votes >= proposals[i].votes, "This Proposal is not the highest voted");
        }

        // Does the Proposal have sufficient votes (quorum)
    }
}


// Proposal ko create krne ka bhi time hona chahiye, ek baar woh creation time khatamn ho gya tab hi hum display karenge sabhi proposals ko