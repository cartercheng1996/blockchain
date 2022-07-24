// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

/// @title Contract to agree on the lunch venue
contract LunchVenueUpdated {
    
    struct Friend {
        string name ;
        bool voted ;
    }

    struct Vote {
        address voterAddress ;
        uint venue ;
    }

    mapping ( uint => string ) public venues ; // List of venues ( venue no , name )
    mapping ( address => Friend ) public friends ; // List of friends ( address , Friend )
    uint public numVenues = 0;
    uint public numFriends = 0;
    uint public numVotes = 0;
    uint public time_Out ;
    address public manager ; // Manager of smart contract
    string public votedVenue = ""; // Where to have lunch

    mapping ( uint => Vote ) private votes ; // List of votes ( vote no , Vote )
    mapping ( uint => uint ) private results ; // List of vote counts ( venue no , no of votes )
    bool voteOpen = false ; ///////////////// This solve the issue of weakness 2, the vote is not open yet and need mamager to start the vote ////////////////////
    bool stopContract = false ;

    // Creates a new lunch venue contract
    constructor () {
        manager = msg. sender ; // Set contract creator as manager
    }

    /// @notice Add a new lunch venue
    /// @dev To simplify the code duplication of venues is not checked
    /// @param name Name of the venue
    /// @return Number of lunch venues added so far
    ///////////////// This solve the issue of weakness 2,3 and 4 by adding modifier, if the vote started,Time-Out or contract is sign invalid no more new venues can be added ////////////////////
    function addVenue ( string memory name ) public restricted votingClosed notTimeOut contractVaild returns ( uint ){
        numVenues ++;
        venues [ numVenues ] = name ;
        return numVenues ;

    }

    /// @notice Add a new friend who can vote on lunch venue
    /// @dev To simplify the code duplication of friends is not checked
    /// @param friendAddress Friend ’s account address
    /// @param name Friend ’s name
    /// @return Number of friends added so far
    ///////////////// This solve the issue of weakness 2,3 and 4 by adding modifier, if the vote started, Time-Out or contract is sign invalid, no more new friends can be added ////////////////////
    function addFriend ( address friendAddress , string memory name ) public restricted votingClosed notTimeOut contractVaild returns ( uint ){
        Friend memory f;
        f. name = name ;
        f. voted = false ;
        friends [ friendAddress ] = f;
        numFriends ++;
        return numFriends ;
    }

    /// @notice Vote for a lunch venue
    /// @dev To simplify the code multiple votes by a friend is not checked
    /// @param venue Venue number being voted
    /// @return validVote Is the vote valid ? A valid vote should be from a registered friend and to a registered venue
    ///////////////// This solve the issue of weakness 2,3 and 4 by adding modifier, if the  Time-Out or contract is sign invalid, no more votes can be made ////////////////////
    function doVote ( uint venue ) public votingOpen notTimeOut contractVaild returns ( bool validVote ){
        validVote = false ; // Is the vote valid ?
        if ( bytes ( friends [ msg . sender ]. name ). length != 0) { // Does friend exist ?
            if ( bytes ( venues [ venue ]) . length != 0) { // Does venue exist ?
                if(!friends [msg . sender].voted){
                    validVote = true ;
                    friends [msg . sender ]. voted = true ;
                    Vote memory v;
                    v. voterAddress = msg . sender ;
                    v. venue = venue ;
                    numVotes ++;
                    votes [ numVotes ] = v;
                }

            }
        }

        if ( numVotes >= numFriends /2 + 1) { // Quorum is met
            finalResult () ;
        }
        return validVote ;
    }

    ///////////////// This solve the issue of weakness 2, the manager can control the starting of the vote////////////////////
    ///@notice Begin the vote process
    function beginVote () public restricted votingClosed contractVaild returns (bool) {
        voteOpen=true;
        return voteOpen;
    }

    ///////////////// This solve the issue of weakness 2, the manager can control the ending of the vote////////////////////
    ///@notice End the vote process
    function endVote () public restricted votingOpen contractVaild returns (bool){
        voteOpen=false;
        return voteOpen;
    }

    ///////////////// This solve the issue of weakness 4, the manager can control to stop the contract////////////////////
    ///@notice End the contract
    function endContract () public restricted contractVaild returns (bool){
        stopContract=true;
        return true;
    }
    
    ///////////////// This solve the issue of weakness 4, the manager can control to re-start the contract////////////////////
    ///@notice Re-Start the contract
    function startContract () public restricted returns (bool){
        stopContract=false;
        return true;
    }

    /// @notice Determine winner venue
    /// @dev If top 2 venues have the same no of votes , final result depends on vote order
    function finalResult () private {
        uint highestVotes = 0;
        uint highestVenue = 0;

        for ( uint i = 1; i <= numVotes ; i++) { // For each vote
            uint voteCount = 1;
            if( results [ votes [i]. venue ] > 0) { // Already start counting
                voteCount += results [ votes [i]. venue ];
            }
            results [ votes [i]. venue ] = voteCount ;

            if ( voteCount > highestVotes ){ // New winner
                highestVotes = voteCount ;
                highestVenue = votes [i]. venue ;
            }
        }
        votedVenue = venues [ highestVenue ]; // Chosen lunch venue
        voteOpen = false ; // Voting is now closed
    }
    
    ///////////////////////////Weakness3: Set Time-Out for the contract////////////////////////////
    ///@notice This allow manager to set timeout based on current block number
    function defineTimeOut (uint Num_Block) public restricted returns(bool) {
        time_Out = Num_Block + block.number;
        return true;
    }
    
    /// @notice Only manager can do
    modifier restricted () {
        require ( msg . sender == manager , "Can only be executed by the manager");
        _;
    }

    /// @notice Only whenb voting is still open
    modifier votingOpen () {
        require ( voteOpen == true , "Can vote only while voting is open") ;
        _;
    }

    /// @notice Only whenb voting is close
    /// For weakness 2 and 4, add voting close modifier
    modifier votingClosed () {
        require ( voteOpen == false , "Can do it only while voting is closed") ;
        _;
    }

    /// @notice Only allow to vote if not Time-out
    /// For weakness 2, add Time-out modifier
    modifier notTimeOut(){
        require(block.number<time_Out, "Can do it only when not Time-Out");
        _;
    }

    /// @notice Only allow to excute the contract if it is vaild
    /// For weakness 4, add contract_vaild modifier
    modifier contractVaild(){
        require( stopContract==false, "Can do it only when contract is vaild");
        _;
    }



 }
