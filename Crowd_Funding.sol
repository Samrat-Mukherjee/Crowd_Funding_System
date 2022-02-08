// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract CrowdFunding {
    address public manager;
    uint256 public target;
    uint256 public deadline;
    uint256 public minContribution;
    mapping(address => uint256) public contributors;
    uint256 public raiseAmount;
    uint256 public numOfContributors;

    constructor(uint256 _deadline, uint256 _target) {
        deadline = block.timestamp + _deadline;
        target = _target;
        manager = msg.sender;
        minContribution = 1 ether;
    }

    struct Request {
        string description;
        address payable recipint;
        uint256 value;
        bool completed;
        uint256 noOfVoters;
        mapping(address => bool) voters;
    }

    mapping(uint256 => Request) public requests;
    uint256 public numOfRequest;

    function payment() public payable {
        require(block.timestamp < deadline, "Your DeadLine is Ended");
        require(msg.value > minContribution, "Min Amount is 1 Ether");

        if (contributors[msg.sender] == 0) {
            numOfContributors++;
        }

        contributors[msg.sender] += msg.value;
        raiseAmount += msg.value;
    }

    function getContractBalance() public view returns (uint256) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function refund() public {
        require(
            raiseAmount < target && block.timestamp > deadline,
            "You are not eligible for refund"
        );
        require(contributors[msg.sender] > 0);
        address payable user = payable(msg.sender);
        user.transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
    }

    modifier onlyManager() {
        require(manager == msg.sender, "Only Manegar Can Access This");
        _;
    }

    function createRequest(
        string memory _description,
        address payable _recipient,
        uint256 _value
    ) public onlyManager {
        Request storage newRequest = requests[numOfRequest];
        numOfRequest++;
        newRequest.description = _description;
        newRequest.recipint = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.noOfVoters = 0;
    }

    function voteRequest(uint256 _requestNo) public {
        require(
            contributors[msg.sender] > 0,
            "First You Need to Be a Contributor"
        );
        Request storage thisRequest = requests[_requestNo];
        require(
            thisRequest.voters[msg.sender] == false,
            "You have already voted"
        );
        thisRequest.voters[msg.sender] = true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint256 _requestNo) public onlyManager {
        require(raiseAmount >= target);
        Request storage thisRequest = requests[_requestNo];
        require(thisRequest.completed == false);
        require(
            thisRequest.noOfVoters > numOfContributors / 2,
            "Mejority is not Supporting You...."
        );
        thisRequest.recipint.transfer(thisRequest.value);
        thisRequest.completed = true;
    }
}
