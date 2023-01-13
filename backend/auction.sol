// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IERC721 {
    function safeTransferFrom(address from, address to, uint tokenId) external;
    //approving nft transfer from seller to sc for auction process to start
    function transferFrom(address, address, uint) external;
}

contract auction {
    event Start();
    event Bid(address indexed sender, uint amount); 
    event Withdraw(address indexed bidder, uint amount); //indexed because there can be many bidder
    event End(address winner, uint amount);

    IERC721 public nft; //storing nft
    uint public nftId;

    address payable public seller;
    uint public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint public highestBid;
    mapping(address => uint) public bids; //storing bids(that are not the highest bid) of an address. will allow to withdraw bid/bids if not highest seller

    constructor(address _nft, uint _nftId, uint _startingBid) {
        nft = IERC721(_nft); //nft of seller that is gonna be listed
        nftId = _nftId; 

        seller = payable(msg.sender); //the one who deploys sc is auctioning his nft
        highestBid = _startingBid; //decided by seller
    }

    function start() external {
        require(!started, "started"); //auction should be started once only
        require(msg.sender == seller, "not seller");

        nft.transferFrom(msg.sender, address(this), nftId); //transferring ownership of nft from seller to this sc
        started = true;
        endAt = block.timestamp + 7 days; //from current time until 7 days 

        emit Start();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "ended");
        require(msg.value > highestBid, "value < highest");

        //part of withdrawing previous high bid to previous highest bidder
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        } //if to protect 0th address from refunding

        highestBidder = msg.sender;
        highestBid = msg.value;

        emit Bid(msg.sender, msg.value);
    } 

    //function to withdraw bid
    function withdraw() external {
        uint bal = bids[msg.sender];
        //reset balance first
        bids[msg.sender] = 0; //if we transfer eth before resetting balance, there can be a reentrancy attack
        //then transfer eth
        payable(msg.sender).transfer(bal); 

        emit Withdraw(msg.sender, bal);
    }

    //function to end auction after time(of endAt) has passed
    function end() external {
        require(started, "not started");
        require(block.timestamp >= endAt, "not ended");
        require(!ended, "ended");

        ended = true;
        if (highestBidder != address(0)) 
        {
            nft.safeTransferFrom(address(this), highestBidder, nftId);//address(this) is the sc address which owns nft 
            seller.transfer(highestBid); //eth earned from highest bid goes to owner of nft
        } else {
            //if noone bid then
            nft.safeTransferFrom(address(this), seller, nftId); //nft going back to seller/owner from sc
        }

        emit End(highestBidder, highestBid);
    }
}
