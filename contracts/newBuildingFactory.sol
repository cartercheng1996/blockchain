// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;

import "./newBuilding.sol";

// import "@openzeppelin/contracts/utils/Strings.sol";


// suggestion on factory inmplementation taked from here: https://blog.logrocket.com/cloning-solidity-smart-contracts-factory-pattern/
contract newBuildingFactory { 
    
    //structure to record common information for all new buildings contracts
    struct newBuildingInstance {
        string buildingName;
        address developer;
    }

    //this struct is separately created for more convenient usage for as a temporary storage in "show..." functions
    struct tempForReturn {
            string name;
            address addr;
           
        }

    //mapping-array pairs to record contracts' addresses and state of those contracts
    //array is needed for looping, mapping is good for cheap and quick retieval of information
    mapping (address => newBuildingInstance) private listOfNewBuildings;
    address[] private allNewBuildingsAddresses;
    
    mapping (address => newBuildingInstance) private listOfWrongContracts;
    address[] private allWrongContractsAddresses;
    
    mapping (address => newBuildingInstance) private listOfCompletedBuildings;
    address[] private allCompletedBuildingsAddresses;


    
    // function to create new building contract. It is accessable to everybody and 'msg.sender' is recorded as developer bioth here and in relevant building contract
    function createNewBuilding (string memory buildingName_) public {

        address newInstance = address(new newBuilding(msg.sender, buildingName_));
        newBuildingInstance memory nb;
        nb.buildingName = buildingName_;
        nb.developer = msg.sender;
        listOfNewBuildings[newInstance] = nb;
        allNewBuildingsAddresses.push(newInstance);
    }


    //auxiliary view function for internal use by functions below
    //it looks uo for index number where sought contract address is stored in array
    function findIndex (uint location, address addrSought) private view returns (uint indexNo) {
        indexNo = 0;
        // values for 'location' mean:
        // 1 = "allNewBuildingsAddresses";
        // 2 = "allWrongContractsAddresses";
        // 3 = "allCompletedBuildingsAddresses"

        if (location == 1) {
            for (uint i = 0; i<allNewBuildingsAddresses.length; i++) {
                if (allNewBuildingsAddresses[i] == addrSought) {
                    indexNo = i;
                    return indexNo;
                }
            }
        } else if (location == 2) {
            for (uint i = 0; i<allWrongContractsAddresses.length; i++) {
                if (allWrongContractsAddresses[i] == addrSought) {
                    indexNo = i;
                    return indexNo;
                }
            }

        } else if (location == 3) {
            for (uint i = 0; i<allCompletedBuildingsAddresses.length; i++) {
                if (allCompletedBuildingsAddresses[i] == addrSought) {
                    indexNo = i;
                    return indexNo;
                }
            }
        }
    }
    

    //function to disable or re-enable contract. It is called form other functions below and executes call to the required building address
    function disable_or_enableContract (address contractAddress) private {
        (bool success, bytes memory result) = contractAddress.call(abi.encodeWithSignature("disableOrEnableContract()"));
        result = result;
        require(success == true, "Disabling or enabling contract transaction failure");
    }


    //function allowing to disable 'wrong' contract and move it to appropriate mapping-array storage for future reference (if needed)
    function disableWrongContract (address wrongContractAddress) public {
        require(bytes(listOfNewBuildings[wrongContractAddress].buildingName).length != 0, "Requested contract address was not found in 'listOfNewBuildings'" );
        require(msg.sender == listOfNewBuildings[wrongContractAddress].developer, "Can only be executed by the Developer of this building");      
        disable_or_enableContract(wrongContractAddress);
        listOfWrongContracts[wrongContractAddress] = listOfNewBuildings[wrongContractAddress];
        delete listOfNewBuildings[wrongContractAddress];
        uint indexNo = findIndex(1, wrongContractAddress); //1 means "allNewBuildingsAddresses"
        allWrongContractsAddresses.push(allNewBuildingsAddresses[indexNo]);
        allNewBuildingsAddresses[indexNo] = allNewBuildingsAddresses[allNewBuildingsAddresses.length - 1];
        allNewBuildingsAddresses.pop();       
    }

    //function allowing to disable contract for already completed building and move it to appropriate mapping-array storage for future reference (if needed)
    function disableCompletedBuilding (address completedBuildingAddress) public {
        require(bytes(listOfNewBuildings[completedBuildingAddress].buildingName).length != 0, "Requested contract address was not found in 'listOfNewBuildings'" );
        require(msg.sender == listOfNewBuildings[completedBuildingAddress].developer, "Can only be executed by the Developer of this building");      
        disable_or_enableContract(completedBuildingAddress);
        listOfCompletedBuildings[completedBuildingAddress] = listOfNewBuildings[completedBuildingAddress];
        delete listOfNewBuildings[completedBuildingAddress];
        uint indexNo = findIndex(1, completedBuildingAddress); //1 means "allNewBuildingsAddresses"
        allCompletedBuildingsAddresses.push(allNewBuildingsAddresses[indexNo]);
        allNewBuildingsAddresses[indexNo] = allNewBuildingsAddresses[allNewBuildingsAddresses.length - 1];
        allNewBuildingsAddresses.pop();
    }


    //function allowing to re-enable contract move it to appropriate mapping-array record (in case if it was accidentally wrongly disabled)
    function re_enableContract (address contractAddress) public {
        require(bytes(listOfCompletedBuildings[contractAddress].buildingName).length != 0 || bytes(listOfWrongContracts[contractAddress].buildingName).length != 0, "Requested contract address was not found neither in 'listOfNewBuildings' nor in 'listOfCompletedBuildings'" );
        disable_or_enableContract(contractAddress);
        if (bytes(listOfCompletedBuildings[contractAddress].buildingName).length != 0) {
            listOfNewBuildings[contractAddress] = listOfCompletedBuildings[contractAddress];
            delete listOfCompletedBuildings[contractAddress];
            uint indexNo = findIndex(3, contractAddress); // 3 means "allCompletedBuildingsAddresses"
            allNewBuildingsAddresses.push(allCompletedBuildingsAddresses[indexNo]);
            allCompletedBuildingsAddresses[indexNo] = allCompletedBuildingsAddresses[allCompletedBuildingsAddresses.length - 1];
            allCompletedBuildingsAddresses.pop();

        } else {
            listOfNewBuildings[contractAddress] = listOfWrongContracts[contractAddress];
            delete listOfWrongContracts[contractAddress];
            uint indexNo = findIndex(2, contractAddress); // 2 means "allWrongContractsAddresses"
            allNewBuildingsAddresses.push(allWrongContractsAddresses[indexNo]);
            allWrongContractsAddresses[indexNo] = allWrongContractsAddresses[allWrongContractsAddresses.length - 1];
            allWrongContractsAddresses.pop();
        }
    }
    
    
    // function allowing everybody to see list of all active building contracts
    function showListOfNewBuildings() public view returns (tempForReturn[] memory) {
        
        tempForReturn[] memory allNewBuildings = new tempForReturn[](allNewBuildingsAddresses.length); //https://blog.finxter.com/how-to-return-an-array-of-structs-in-solidity/
        
        for (uint i=0; i<allNewBuildingsAddresses.length; i++) {
            tempForReturn memory t;
            t.name = listOfNewBuildings[allNewBuildingsAddresses[i]].buildingName;
            t.addr = allNewBuildingsAddresses[i];
            allNewBuildings[i] = t;
        }

        return allNewBuildings;
    } 


    // function allowing everybody to see list of all disabled 'wrong' building contracts
    function showListOfWrongContracts() public view returns (tempForReturn[] memory) {
        tempForReturn[] memory allWrongContracts = new tempForReturn[](allWrongContractsAddresses.length);  // https://blog.finxter.com/how-to-return-an-array-of-structs-in-solidity/
        for (uint i=0; i<allWrongContractsAddresses.length; i++) {
            tempForReturn memory t;
            t.name = listOfWrongContracts[allWrongContractsAddresses[i]].buildingName;
            t.addr = allWrongContractsAddresses[i];
            allWrongContracts[i] = t;
        }
        
        return allWrongContracts;
    } 


    // function allowing everybody to see list of all disabled already completed building contracts
    function showListOfCompletedBuildings() public view returns (tempForReturn[] memory) {
        tempForReturn[] memory allCompletedBuildings = new tempForReturn[](allCompletedBuildingsAddresses.length);  // https://blog.finxter.com/how-to-return-an-array-of-structs-in-solidity/
        for (uint i=0; i<allCompletedBuildingsAddresses.length; i++) {
            tempForReturn memory t;
            t.name = listOfCompletedBuildings[allCompletedBuildingsAddresses[i]].buildingName;
            t.addr = allCompletedBuildingsAddresses[i];
            allCompletedBuildings[i] = t;
        }
        
        return allCompletedBuildings;
    } 


}
