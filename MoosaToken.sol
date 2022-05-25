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
    string public name = "MoosaHaseem";
    string public symbol = "MH";
    uint public decimals = 0;

    uint public supply;
    address public founder;

    mapping (address=>uint) public balances;
    mapping(address=>mapping(address=>uint)) allowed;

    //events allow you to write data on the blockchain
    //a log of something that happened i.e; --> for stuff that you want to keep a record of but not change later

    //event Transfer ( address indexed from, address indexed to, uint tokens);
    
    constructor() {
        supply = 500000;
        founder = msg.sender;
        balances[founder] = supply;
    }

    modifier isFounder() {
         require(msg.sender == founder, "You are not the Creator of this Coin, Calm Down");
         _;
     }

    function allowance(address tokenOwner, address spender ) public view override returns (uint remaining) {
        return allowed[tokenOwner][spender];
    }

    function approve( address spender, uint tokens ) public override returns (bool success) {
        require(balances[msg.sender] >= tokens);
        require(tokens > 0);
        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);
        return true;
    } 


    function transferFrom (address from, address to, uint tokensToBeSent) public virtual override returns (bool success) {
        require(allowed[from][to] > tokensToBeSent );
        require(balances[from] >= tokensToBeSent);
        balances[from] = balances[from] - tokensToBeSent;
        balances[to] = balances[to] + tokensToBeSent;
        allowed[from][to] = allowed[from][to] - tokensToBeSent;
        return true;
    }

    function totalSupply() public view override returns(uint) {
        return supply;
    }

    function balanceOf( address User ) public view override returns (uint balance) {
        return balances[User];
    } 

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
    address public admin;
    address payable public depositAddress;
    uint public tokenPrice = 0.05 ether;
    uint public hardCap = 300 ether;
    uint public raisedAmount;
    uint public crowdFundStart = block.timestamp;
    uint public crowdFundEnd= crowdFundStart + 7 days;

    uint coinTradeStart = crowdFundEnd + 7 days;

    uint public maxInvestment= 2 ether;
    uint public minInvestment= 0.05 ether;

    enum State{beforeStart, Running, afterEnd, Halted}
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

    function halt() public onlyAdmin{
        icoState=State.Halted;
    }
    
    function unhalt() public onlyAdmin{
        icoState=State.Running;
    }

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

    function transfer( address to, uint tokensToBeSent) public override returns (bool) {
        require(block.timestamp > coinTradeStart);
        super.transfer(to,tokensToBeSent);
    }

    function transferFrom( address from, address to, uint tokensToBeSent) public override returns (bool) {
        require(block.timestamp > coinTradeStart);
        super.transferFrom(from,to,tokensToBeSent);
    }

    function burn() public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
    }



}   