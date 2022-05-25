// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

interface ERC20Interface {

    //they are all external b/c they have to be overridden because they have to extended and overriden by moosaToken Class

    function totalSupply() external view returns (uint);
    //current balance of owner calling the function
    function balanceOf(address tokenOwner) external view returns (uint balance);

    //allowance function is basically the founder, allowing the two users to take part in this transaction
    //it is there to basically control how much of token is transfered and for what purpise
    function allowance(address tokenOwner, address spender) external view returns (uint remaining);
   
   //transfer token
    function transfer(address to, uint tokens) external returns (bool success);
  
    //transfer but specify both recv and send address
    function transferFrom(address from, address to, uint tokens) external returns (bool success);

   //approve the transfer
    function approve(address spender, uint tokens) external returns (bool success);
    
    
    //indexed allows us to search for events based on the indexed parameters as filters
    event Transfer(address indexed from, address indexed to, uint tokens);
    event Approval(address indexed tokenOwner, address indexed spender, uint tokens);
}

contract moosaToken is ERC20Interface {

    //token name and symbol
    string public name = "MoosaHaseem";
    string public symbol = "MH";


    uint public supply;
    address public founder;


    //track how much balance each address has
    mapping (address=>uint) public balances;
    //allowed is explained above in interface
    mapping(address=>mapping(address=>uint)) allowed;

    //events allow you to write data on the blockchain
    //a log of something that happened i.e; --> for stuff that you want to keep a record of but not change later

    //event Transfer ( address indexed from, address indexed to, uint tokens);
    
    constructor() {

        //maximum tokens available, the first person who deploys the contract is the founder or creator 
        //of the coin and holds all of the coins intiially
        supply = 500000;
        founder = msg.sender;
        balances[founder] = supply;
    }

    modifier isFounder() {
         require(msg.sender == founder, "You are not the Creator of this Coin, Calm Down");
         _;
     }

    //explained above
    function allowance(address tokenOwner, address spender ) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    //this is a check to see whether the amount of tokens the person calling want to trasnfer
    //and whether they even have those many tokens available or not
    function approve( address spender, uint tokensToBeSpent ) public override returns (bool success) {
        require(balances[msg.sender] >= tokensToBeSpent);
        require(tokensToBeSpent > 0);
        allowed[msg.sender][spender] = tokensToBeSpent;
        //write to blockchain the success of the POSSIBILITY of the transaction
        //this approve function is necessary b/c as he explained, information about token transfer 
        //and available money must be propogated through the blockchain so everyone should have the record of it
        //is this why we emit it?
        emit Approval(msg.sender, spender, tokensToBeSpent);
        return true;
    } 


    //like transfer but you specify transferform --> this would be dangerous to give functionality to other people to transfer 
    //money from separate address but that is why we have admins and the allowed function
    // --> confirm with sir
    function transferFrom (address from, address to, uint tokensToBeSent) public virtual override returns (bool success) {
        require(allowed[from][to] > tokensToBeSent );
        require(balances[from] >= tokensToBeSent);
        balances[from] = balances[from] - tokensToBeSent;
        balances[to] = balances[to] + tokensToBeSent;
        allowed[from][to] = allowed[from][to] - tokensToBeSent;
        return true;
    }

    //self explanatory
    function totalSupply() public view override returns(uint) {
        return supply;
    }

    //current available coins of function caller
    function balanceOf( address User ) public view override returns (uint balance) {
        return balances[User];
    } 


    //like transfer --> explained above
    function transfer(address to, uint tokensToBeSent) public virtual returns (bool success) {
        require (balances[msg.sender] >= tokensToBeSent);
        require( tokensToBeSent > 0 );
        balances[to] = balances[to] +tokensToBeSent;
        balances[msg.sender] = balances[msg.sender] - tokensToBeSent;
        emit Transfer(msg.sender, to, tokensToBeSent);
        return true;
    }
}

contract moosaICO is moosaToken {

   
    address public admin;  // guy with rights to make changes
    address payable public depositAddress; // address for transfer
    uint public tokenPrice = 0.05 ether; //price of token
    uint public hardCap = 300 ether; // price cannot be more than this eva --> done ot ocntorl economy
    uint public raisedAmount;
    uint public crowdFundStart = block.timestamp; 
    uint public crowdFundEnd= crowdFundStart + 7 days; // I used 7 days b/c it was like that in the example sir did

    uint coinTradeStart = crowdFundEnd + 7 days; // I used 7 days b/c it was like that in the example sir did

    uint public maxInvestment= 2 ether; 
    uint public minInvestment= 0.05 ether;

    enum State{beforeStart, Running, afterEnd, Halted} //according to ERC20 guidelines we must have these states
    State public icoState;

    modifier onlyAdmin {
        require (msg.sender ==admin);
        _;
    }
    
    event Invest (address investor, uint value, uint tokensToBeSent);

    constructor(address payable _deposit) {
        depositAddress = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    //halting in case of emergencies
    function halt() public onlyAdmin{
        icoState=State.Halted;
    }

    //for exchange of this ICO to occur, the state of the ICO must NOT be halted    
    function unhalt() public onlyAdmin{
        icoState=State.Running;
    }

    //to change from admin!
    function changeDepositAddress (address payable _depositAddress) public onlyAdmin {
        depositAddress = _depositAddress;
    }

    function getCurrentState() public view returns (State) {
        if(icoState==State.Halted){
            return State.Halted;
        }
        else if(block.timestamp < crowdFundStart){
            return State.beforeStart;
        }else if(block.timestamp >= crowdFundStart && block.timestamp <= crowdFundEnd){
            return State.Running;
        }else {
            return State.afterEnd;
        }
    }

    function invest() payable public returns (bool) {
        icoState=getCurrentState();
        require(icoState==State.Running);
        require(msg.value >= minInvestment && msg.value <= maxInvestment);
        uint tokensInvested = msg.value/tokenPrice;
        require(raisedAmount + msg.value <= hardCap);
        raisedAmount = raisedAmount + msg.value;
        balances[msg.sender] += msg.value;
        balances[founder] -= msg.value;
        depositAddress.transfer(msg.value);
        emit Invest(msg.sender, msg.value, tokensInvested);
        return true;
    }

    //same as the one in moosaToken --> function of parent called
    function transfer( address to, uint tokensToBeSent) public override returns (bool) {
        require(block.timestamp > coinTradeStart);
        super.transfer(to,tokensToBeSent);
    }

        //same as the one in moosaToken --> function of parent called
    function transferFrom( address from, address to, uint tokensToBeSent) public override returns (bool) {
        require(block.timestamp > coinTradeStart);
        super.transferFrom(from,to,tokensToBeSent);
    }

    //makes the tokens permanently unspendable
    //permanently removed from circulation
    //not sure if this works but it is what was there in sir's example and stackoverflow
    function burn() public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
    }



}   