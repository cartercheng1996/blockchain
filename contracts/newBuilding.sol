// SPDX-License-Identifier: UNLICENSED

//6452-22T2 Assignment2-part2 group SC9


//README (main usage explanation):
//This is contract from which public can access trusted information backed up by immutability of blockchain.
//This contract represents one building and stores all info related to this building.
//Public can see:
// 1) general inforamtion about the building (via below function 'generalInfo');
// 2) list of all maerials which were delivered to this building (via below function 'showListOfMaterials');
// 3) overview for each material of interest (via below function 'showOverviewOfMaterial'). 
//Here public can see all 'newBatch' contracts for the material of interest (e.g.steel etc.) which were assigned to this building, 'assignmentId' at which this particular newBatch was assigned
//and quantity of material assigned at this 'assignementId'.
// 'assignmentId' is needed because the same newBatch can be part of different assignments if different contractors from this building owned share of the same newBatch contract and assigned their shares
// 4) knowing  'newBatch' contract of interest public would be able to access relevant 'newBatch' contract and via hash of conformance certificat stored in 'newBatch' contract with help of reverse oracle public would be able to 
// retrive copy of conformace certificate from off-chain storage (oracle implemented in front-end). Hash would ve confirmation of the immutability of this certificate;
// 5) knowing "assignemntId" of interest public would be able to request information on supply chain for this assignement (via below function 'showSupplyChain'). this will return addresses and names of all 
// contractors and manufacturer who owned this material from manufacturer till the assignemt to the building.
//6) public will be able to see all registered on this building contractors (via below function 'showAllRegisteredContractors')

//Developer have to register all contractors working on this building (via below function 'addContractor') before registered contractor can assign any materials to the building.
//Crucial for contractors is 'assignMaterial' external function called from within newBatch contract. It can be called only by registered in 'newBuilding' contract contractor.

//Further functionality is described in below comments to the functions


pragma solidity >=0.8.00 <0.9.0;


import "@openzeppelin/contracts/utils/Strings.sol";
import "https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol";



contract newBuilding {

    
    //structure for recording information relted to every assignment of material to the building
    struct Batch {
        uint assignementId; //It is needed as the same material batch contract can be assigned to the building more than once by different contractors
        address batchContractAddress;
        uint quantityAssigned;
        string quantityUnit;
    }

    // structure for recording information about every supplier in supply chain of the material assigned to the building
    struct supplier {
        address supplierAddress;
        string supplierName;
    }

    
    bool private contractIsDisabled = false; //variable to disable execution function in this contract but to leave view options 
    address private factoryContractAddress; // variable needed to record parent factory contract address in order to modify access to 'disableOrEnableContract' function which is 
                                            //supposed to be executed only from paren factory address
    uint private assignement_number = 1; //starting number of assignemt for material batch. It is needed as the same material batch contract can be assigned to the building more than once by different contractors
    
    string[] private listOfMaterials; //=['']? variable to record all different names of materials and then group all assigned materials by these different names (i.e. steel, glass etc.)
    mapping (string => Batch[]) private listOfBatches; //(name of material from 'listOfMaterials' => array of 'Batch' to store all batches related to the same name of material)
    
    mapping (uint => supplier[]) private supplyChain; // (assignementId -> string of all previous material owners)
    
    address[] private allContractorsAddresses; // array to store addresses of all contractors to be able later to loop through them and retrieve contractor's name from mapping 'listOfContractors'
    mapping (address => string) private listOfContractors; //(contractor's address => contractor's name)

    //this structure is created as auxiliary for temporary storage and returning from 'showAllRegisteredContractors' function
    struct tempContractor {
        string name;
        address addr;
    }

    
    address private Developer;
    address private BuildingAddress;
    string private BuildingName;

    constructor (address build_developer, string memory name) { 
        BuildingName = name;
        Developer = build_developer; 
        listOfContractors[Developer] = "Developer"; 
        allContractorsAddresses.push(Developer); //record info about developer
        BuildingAddress = address(this); //record current contract address (if this contract eventiually is not recorded on the chain 
                                        // for any building a day does not matter at all so if Developer sees next day that this contract was not actually included into chain 
                                        //Developer will be able to remove this contract via function in parent factory contract and then create new one
        factoryContractAddress = msg.sender;

    }


//===================FOR PUBLIC TO QUERY=====================================================================================    
    
    
    function generalInfo () public view returns (string memory Building_Name, address Building_Address, address Developer_Address) {
        Building_Name = BuildingName;
        Building_Address = BuildingAddress;
        Developer_Address = Developer;
        return (Building_Name, Building_Address, Developer_Address);
    }
    


    // function to see all materil names assigned to the building (i.e. steel, glass, timber etc.)
    function showListOfMaterials () public view returns (string[] memory ) {
        
        return listOfMaterials;
    }


    // function allowing public to see all batches of particular material (e.g. steel) assigned to the building and find address and 'assignementId' for batch of interest
    function showOverviewOfMaterial (string memory material) public view returns  (Batch[] memory) { 
        //https://www.cloudhadoop.com/solidity-mapping-check-object-exists/ 
        require((listOfBatches[material].length > 0) == true, "Please try again as requested material was not found");         
        Batch[] memory batchesList = new Batch[](listOfBatches[material].length);


        for (uint i=0; i<listOfBatches[material].length; i++) {
            Batch memory ba;
            ba.assignementId = listOfBatches[material][i].assignementId;
            ba.batchContractAddress = listOfBatches[material][i].batchContractAddress;
            ba.quantityAssigned = listOfBatches[material][i].quantityAssigned;
            ba.quantityUnit = listOfBatches[material][i].quantityUnit;
            batchesList[i] = ba;  
        }
        return batchesList;
        
    }

    // function which allows public to see whole supply chain of the material assigned at particular 'assignementId'
    function showSupplyChain (uint assignId) public view returns (string memory chainOfSupply) {
        require((supplyChain[assignId].length > 0) == true, "Please try again as requested supply chain number was not found");
        chainOfSupply = "\n";
        string memory  supplier_address_str;
        string memory supplier_name;
        
        for (uint i=0; i<supplyChain[assignId].length; i++) {
            supplier_address_str = Strings.toHexString(supplyChain[assignId][i].supplierAddress);
            supplier_name = supplyChain[assignId][i].supplierName;
            
            chainOfSupply = string(abi.encodePacked( chainOfSupply, " ( ", supplier_address_str, " : ", supplier_name , " ) -> \n" ));  //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
        }
        chainOfSupply = string(abi.encodePacked(chainOfSupply, " ", BuildingName));
        return chainOfSupply;
    } 

    // function allowing public to see all contractors registered on the building of interest
    function showAllRegisteredContractors() public view returns (tempContractor[] memory) {
        tempContractor[] memory allContractors = new tempContractor[](allContractorsAddresses.length);
        
        for (uint i=0; i<allContractorsAddresses.length; i++) {
            tempContractor memory tc;
            tc.name = listOfContractors[allContractorsAddresses[i]];
            tc.addr = allContractorsAddresses[i];
            allContractors[i] = tc;
        }
        return allContractors;
    } 

//============================================================================================================================







//===================FOR DEVELOPER TO SET UP==================================================================================    


    //only developer is allowed to assign contractors to the building. This is needed to control who can assign materials to the building
    function addContractor ( address contractor_Address, string memory name_ ) public onlyByDeveloper disabledContract {
        require(bytes(listOfContractors[contractor_Address]).length == 0, "Contractor is already registered" );
        listOfContractors[contractor_Address] = name_ ;
        allContractorsAddresses.push(contractor_Address);
        
    }

    modifier onlyByDeveloper() {
        require(tx.origin == Developer, "Can only be executed by the Developer");
        _;
    }

//============================================================================================================================






//===================FOR REGISTERED CONTRACTOR TO ASSIGNING MATERIAL===========================================================
    
    //function for registered contractors to assign material and provide all data about this assigned material
    function assignMaterial (string memory material, uint quantity, string memory unit, address[] memory supplAddresses, string[] memory supplNames, address batchAddress) external onlyByRegisteredContractor disabledContract {  // , 
               
        if (listOfBatches[material].length == 0) { //check whether material name already exists
            listOfMaterials.push(material);
        }
        
        Batch memory b;
        b.assignementId = assignement_number;
        b.batchContractAddress = batchAddress;
        b.quantityAssigned = quantity;
        b.quantityUnit = unit;
        listOfBatches[material].push(b);
        
        supplier memory sup;

        for (uint i=0; i<supplAddresses.length; i++) {
            sup.supplierAddress = supplAddresses[i];
            sup.supplierName = supplNames[i];
            supplyChain[assignement_number].push(sup);
        }

        //updating contractor's name with the name recorded by developer during contractor's registration to avoid confusion whiich might be caused if
        //contractor's name is different in list of registered contractors to name recorded on batch certificate (in any case contractor's address will be identical in both records)
        supplyChain[assignement_number][supplyChain[assignement_number].length - 1].supplierName = listOfContractors[tx.origin];
        
        assignement_number++;
    }


    modifier onlyByRegisteredContractor() {
        require(bytes(listOfContractors[tx.origin]).length != 0, "Can only be executed by the registered Contractor" );
        _;
    }


//============================================================================================================================

    
    //function for disabling active function of the contract and allowing onlyew view function to be accessible
    //this function is called from parent factory contract only by developer of this building
    function disableOrEnableContract () external {
        require(msg.sender == factoryContractAddress, "Only parent 'newBuildingFactory' contract can call this function");
        contractIsDisabled = !contractIsDisabled;
    }
    
    modifier disabledContract () {
        require(contractIsDisabled == false, "Contract has been disabled");
        _;
    }

}    
