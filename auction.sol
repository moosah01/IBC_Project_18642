// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;


// To make this more interesting --> we could have created a struct with a name , set it's baseAuction price and currentAuction price
// and have people bid on that currentAuction price which is basically highestPayableBid in my example


// ask sir if in bid() func is currstate== aucState.Run now irrelevant because of check
 contract Auction {
    // payable because auctioneer will recieve the highest bid
    // public because everyone using the contract must know who and where to send money to
     address payable public auctioneer;
     address payable public highestBidder;
     
     //create start and end time blocks to measure duration of auction
     //reset these when auction ends I guess --> not sure yet
     uint public aucStart;
     uint public aucEnd;

    //keep track of where auction is currently   
     enum auctionState {End, Run, Cancel}
     auctionState public currState;


    //highestPayableBid is basically to calculate how much to return if ppl paying extra
    //bid Inc is just min value increment that new bids should be than prev greateest bid 
     uint public highestPayableBid;
     uint public bidInc;

    

     mapping (address => uint256) private bids;

     constructor() {
         auctioneer = payable(msg.sender);
         aucStart = block.timestamp;
         aucEnd = aucStart + 7 days;
         bidInc = 1 ether;         
         currState = auctionState.Run;
     }
     
     modifier isAuctioneer() {
         require(msg.sender == auctioneer, "You are not the acution master, Calm Down");
         _;
     }

     modifier isNotAuctioneer() {
         require(msg.sender != auctioneer, "Auctioneer Cannot Place Bids");
         _;
     }

     modifier isStarted() {
         require (block.timestamp > aucStart || currState == auctionState.Run, "Bidding has not started yet");
         _;
     }

     modifier isEnded() {
         require (block.timestamp > aucEnd, "Bidding has ended");
         _;
     }

     function cancelAuc() public isAuctioneer{
        currState = auctionState.Cancel;
     }

     // bro I am not waiting 7 days to test this function   
     function endAuc() public isAuctioneer {
         currState = auctionState.End;
     }

     function min( uint a, uint b) pure private returns (uint) {
        if ( a < b ) {
            return a;
        }
        else return b;
     }

     //store money and find out who is highest bidder
     function bid() payable public isNotAuctioneer isStarted{

        //is the line directly below this needed? --> I have already made a check for this in isStarted 
        require(currState == auctionState.Run);
        require(msg.value >= 1 ether, "Bid must be greater than 1 eth atleast"); // checking for basically the bidInc amount

        //currentBid will be whatever you had previously + whatever u are bidding rn
        uint currentBid = bids[msg.sender] + msg.value;

        // I want to output current valyue of highestPayableBid in the error message how to do that    
        require(currentBid>highestPayableBid, "Too low of a bit to be consider, please bid more" ); 
            // the above error msg should be 
            // value = highestPayableBid;
            // if (bids[msg.sender] > 0) {
            //     value = highestPayableBid - bids[msg.sender] + 1;
            // }
            // Err Message --> bid atleast more than {value}

        bids[msg.sender] = currentBid;

        //determine the highestPayableBid and the highestBidder
        if (currentBid<bids[highestBidder]) {
            highestPayableBid = min(currentBid + bidInc, bids[highestBidder]);
        }   
        else {
            highestPayableBid = min(currentBid, bids[highestBidder] + bidInc );
            highestBidder = payable(msg.sender);
        }
     }

     //if it is cancelled --> return money
     //if it has ended --> pay person who is called highestBidder and return money to losers
     //why make auctionComplete() function and not just send everyone money back automatically?
     
     //hacker can intercept and take money if you send it back automatically
     //we are giving the option button to take back money only to the auctioneer AND the people that have bidded and not normal people that haven't bid
     function completeTheAuction() public {
         require( currState == auctionState.End || currState == auctionState.Cancel || block.timestamp > aucEnd);
         
         //check if it is someone who is either auctioneer or literally anyone who has bid atleast something before
         require(msg.sender == auctioneer || bids[msg.sender]>0);

         address payable giveMoneyTo;
         uint valueOfMoneyReceived;

         //return everyone their money
         if (currState == auctionState.Cancel) {
             giveMoneyTo = payable(msg.sender);
             valueOfMoneyReceived = bids[giveMoneyTo];

         }
         else {
             // it means auction has ended 
             if (msg.sender == auctioneer) {
                 giveMoneyTo = auctioneer;
                 valueOfMoneyReceived = highestPayableBid;
             }
             else {
                 if (msg.sender == highestBidder ) {
                     giveMoneyTo = highestBidder;

                    //whatever money he has in his mapping that can be greater than highest payable bid
                    //so minus it and give it back                   
                     valueOfMoneyReceived = bids[highestBidder] - highestPayableBid;
                 }
                 else {
                     //person who lost the bid
                     giveMoneyTo = payable(msg.sender);
                     
                     //whatever they gave previously store it for returning
                     valueOfMoneyReceived = bids[giveMoneyTo];

                 }
             }
             //now you know who has what amount of money to receive back
             //based on whoever called that function to end the auction / return the money depending on whether auction ended or got cancelled
             

             bids[msg.sender] = 0; // make this 0 because if you don't make it 0 --> someone can just call the function again and again and take the money
             //because the first thing we check for is whether bid[msg.sender] > 0;
             giveMoneyTo.transfer(valueOfMoneyReceived);
         }
     }

 }