pragma solidity >=0.4.22;
// pragma experimental ABIEncoderV2;

import "./Ownable.sol";

contract LendingBoard {
    function contractFee() public pure returns(uint256) {}
}

contract Base is Ownable {

    uint256 lendingRequestCount = 0;
    LendingBoard board;
    uint256 public contractFee = 0;

    struct LendingRequest {
        address payable asker;
        uint amount;
        uint paybackAmount;
        address payable lender;
        bool settled;
        string purpose;
        bool lent;
        uint creationTime;
    }

    mapping(address => uint[]) private userRequests;
    LendingRequest[] public lendingRequests;

    constructor(LendingBoard _address)
        public {

        board = _address;
        contractFee = board.contractFee();
    }


    /**
     * @notice Will return all lending requests of the caller
     */

    function getUserRequests()
        public
        view
        returns (uint[] memory) {

        return userRequests[msg.sender];
    }

    function getContractFee()
        public
        view
        returns (uint256) {

        return board.contractFee();
    }

    /*
        Handle Requests in Webinterface - do not use as database
    */

    // function getLendingRequests() public view returns (LendingRequest[]) {
    //     return lendingRequests;
    // }

    // function getLendingRequestsByUser(address user) public view returns (LendingRequest[]) {
    //     uint[] memory myRequests = userRequests[user];
    //     LendingRequest[] memory fullRequests = new LendingRequest[](myRequests.length);
    //     for (uint i = 0; i < myRequests.length; i++) {
    //         fullRequests[i] = lendingRequests[myRequests[i]];
    //     }
    //     return fullRequests;
    // }

    // function getMyLendingRequests() public view returns (LendingRequest[]) {
    //     return getLendingRequestsByUser(msg.sender);
    // }

    /**
     * @notice Will return the ID of the first unsettled lending request if one exists
     */

    function getMyFirstUnsettledLendingRequest()
        public
        view
        returns (uint256 result) {

        uint256[] memory myRequests = getUserRequests();
        require(hasUnsettledRequests(), "you have no unsettled requests");


        for (uint256 i = 0; i < myRequests.length; i++) {
            if (!lendingRequests[i].settled) {
                result = i;
                break;
            }
        }

        return result;
    }

    function hasUnsettledRequests()
        internal
        view
        returns (bool) {

        uint256[] memory myRequests = getUserRequests();
        bool unsettled = false;

        if (lendingRequests.length == 0 || myRequests.length == 0) {
            return false;
        }

        for (uint256 i = 0; i < myRequests.length; i++) {
            if (!lendingRequests[i].settled) {
                unsettled = true;
                break;
            }
        }
        return unsettled;
    }

    /**
     * @notice Creates a lending request for the amount you specified
     */

    function ask(uint amount, uint paybackAmount, string memory purpose)
        public
        returns (uint) {

        require(amount > 0, "you need to ask for money");
        require(paybackAmount >= amount + getContractFee(), "minimum amount is amount + contractFee");
        // require(userRequests[msg.sender].length == 0, "you already have an open request");
        require(!hasUnsettledRequests(), "you have an unsettled request");

        LendingRequest memory request = LendingRequest({
            asker: msg.sender,
            amount: amount,
            paybackAmount: paybackAmount,
            lender: address(0),
            settled: false,
            purpose: purpose,
            lent: false,
            creationTime: now
            });

        userRequests[msg.sender].push(lendingRequestCount);
        lendingRequests.push(request);
        lendingRequestCount++;
        return lendingRequestCount;
    }

    /**
     * @notice Lend the amount of ether you send to the lending request with the ID you specified
     */

    function lend(uint id)
        public
        payable {

        require(lendingRequests[id].asker != msg.sender, "you cannot lend money to yourself");
        require(!lendingRequests[id].lent, "request was already served");
        require(lendingRequests[id].amount == msg.value, "provided amount has to be equal to the amount asked for");

        lendingRequests[id].asker.transfer(msg.value);
        lendingRequests[id].lent = true;
    }

    /**
     * @notice settle the lending request with the ID you specified
     */

    function settle(uint id)
        public
        payable {

        require(lendingRequests[id].lent, "cannot be settled before money was lent");
        require(!lendingRequests[id].settled, "was already settled");
        require(lendingRequests[id].lender != msg.sender, "no lending money to yourself");
        require(lendingRequests[id].paybackAmount == msg.value, "payback amount has to be equal to the amount agreed upon");

        lendingRequests[id].lender.transfer(msg.value - getContractFee());
        lendingRequests[id].settled = true;
    }

    function contractFees()
        public
        view
        returns (uint) {

        return address(this).balance;
    }

    /**
     * @dev should be called before relinquishing the contract
     */

    function withdrawFees()
        public
        onlyOwner {

        owner.transfer(address(this).balance);
    }

    /**
     * @dev deletes the contract from the chain and transfers all remaining
     * funds to the owner of the contract
     */

    function kill()
    public
    onlyOwner {
        selfdestruct(owner);
    }
}