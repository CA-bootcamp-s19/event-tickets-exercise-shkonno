pragma solidity ^0.5.0;

    /*
        The EventTicketsV2 contract keeps track of the details and ticket sales of multiple events.
     */
contract EventTicketsV2 {

    /*
        Define an public owner variable. Set it to the creator of the contract when it is initialized.
    */
    address payable public owner;
    uint PRICE_TICKET = 100 wei;

    /*
        Create a variable to keep track of the event ID numbers.
    */
    uint public idGenerator;
    
    /*
        Define an Event struct, similar to the V1 of this contract.
        The struct has 6 fields: description, website (URL), totalTickets, sales, buyers, and isOpen.
        Choose the appropriate variable type for each field.
        The "buyers" field should keep track of addresses and how many tickets each buyer purchases.
    */

    struct Event {
        string description;
        string website;
        uint totalTickets;
        uint sales;
        mapping(address => uint) buyers;
        bool isOpen;
        uint id;
    }

    /*
        Create a mapping to keep track of the events.
        The mapping key is an integer, the value is an Event struct.
        Call the mapping "events".
    */

    mapping(uint => Event) public events;

    constructor() public {
        owner = msg.sender;
        idGenerator = 0;
    }

    event LogEventAdded(string desc, string url, uint ticketsAvailable, uint eventId);
    event LogBuyTickets(address buyer, uint eventId, uint numTickets);
    event LogGetRefund(address accountRefunded, uint eventId, uint numTickets);
    event LogEndSale(address owner, uint balance, uint eventId);

    /*
        Create a modifier that throws an error if the msg.sender is not the owner.
    */

    modifier isOwner() {
        require(msg.sender == owner, "You must be the owner of this contract to invoke this function.");
        _;
    }

    /*
        Define a function called addEvent().
        This function takes 3 parameters, an event description, a URL, and a number of tickets.
        Only the contract owner should be able to call this function.
        In the function:
            - Set the description, URL and ticket number in a new event.
            - set the event to open
            - set an event ID
            - increment the ID
            - emit the appropriate event
            - return the event's ID
    */

    function addEvent(string memory eventDescription, string memory websiteUrl, uint numberOfTickets)
    public
    isOwner
    returns (uint newId)
    {
        // initialize new event
        Event memory newEvent;
        newEvent.isOpen = true;
        newEvent.description = eventDescription;
        newEvent.website = websiteUrl;
        newEvent.totalTickets = numberOfTickets;

        // set id
        newId = idGenerator;
        newEvent.id = newId;
        idGenerator += 1;

        // add event to events mapping with a unique id
        events[newId] = newEvent;

        // emit event
        emit LogEventAdded(eventDescription, websiteUrl, numberOfTickets, newId);
    }

    /*
        Define a function called readEvent().
        This function takes one parameter, the event ID.
        The function returns information about the event this order:
            1. description
            2. URL
            3. ticket available
            4. sales
            5. isOpen
    */

    function readEvent(uint eventId)
    public
    view
    returns(string memory eventDescription, string memory websiteUrl, uint ticketsAvailable, uint sales, bool isOpen)
    {
        eventDescription = events[eventId].description;
        websiteUrl = events[eventId].website;
        ticketsAvailable = events[eventId].totalTickets - events[eventId].sales;
        sales = events[eventId].sales;
        isOpen = events[eventId].isOpen;
    }

    /*
        Define a function called buyTickets().
        This function allows users to buy tickets for a specific event.
        This function takes 2 parameters, an event ID and a number of tickets.
        The function checks:
            - that the event sales are open
            - that the transaction value is sufficient to purchase the number of tickets
            - that there are enough tickets available to complete the purchase
        The function:
            - increments the purchasers ticket count
            - increments the ticket sale count
            - refunds any surplus value sent
            - emits the appropriate event
    */

    function buyTickets(uint eventId, uint nTickets)
    public
    payable
    {
        require(events[eventId].isOpen == true, "Event is not open anymore.");
        require(msg.value >= PRICE_TICKET * nTickets, "Not enough ether to buy tickets.");
        require(events[eventId].totalTickets - events[eventId].sales > nTickets, "Not enough tickets left.");

        events[eventId].buyers[msg.sender] += nTickets;
        events[eventId].sales += nTickets;

        // refund extra ether
        msg.sender.transfer(nTickets * PRICE_TICKET - msg.value);

        // emit event
        emit LogBuyTickets(msg.sender, eventId, nTickets);
    }

    /*
        Define a function called getRefund().
        This function allows users to request a refund for a specific event.
        This function takes one parameter, the event ID.
        TODO:
            - check that a user has purchased tickets for the event
            - remove refunded tickets from the sold count
            - send appropriate value to the refund requester
            - emit the appropriate event
    */

    function getRefund(uint eventId) public {
        require(events[eventId].buyers[msg.sender] > 0, "You have no tickets to refund.");
        uint nTickets = getBuyerNumberTickets(eventId);

        // transfer ether to user
        msg.sender.transfer(nTickets * PRICE_TICKET);
        
        // make sure user has no tickets allocated
        events[eventId].buyers[msg.sender] = 0;
        
        // subtract tickets from sales
        events[eventId].sales -= nTickets;

        // emit event
        emit LogGetRefund(msg.sender,eventId, nTickets);
    }

    /*
        Define a function called getBuyerNumberTickets()
        This function takes one parameter, an event ID
        This function returns a uint, the number of tickets that the msg.sender has purchased.
    */

    function getBuyerNumberTickets(uint eventId)
    public
    view
    returns (uint nTickets)
    {
        nTickets = events[eventId].buyers[msg.sender];
    }

    /*
        Define a function called endSale()
        This function takes one parameter, the event ID
        Only the contract owner can call this function
        TODO:
            - close event sales
            - transfer the balance from those event sales to the contract owner
            - emit the appropriate event
    */

    function endSale(uint eventId)
    public
    isOwner
    {
        events[eventId].isOpen = false;
        uint finalBalance = address(this).balance;

        // transfer balance to owner
        owner.transfer(finalBalance);

        // emit event
        emit LogEndSale(owner, finalBalance, eventId);
    }
}
