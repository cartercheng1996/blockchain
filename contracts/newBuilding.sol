// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;

import "@openzeppelin/contracts/utils/Strings.sol";



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
    
    string[] private listOfMaterials; //variable to record all different names of materials and then group all assigned materials by these different names (i.e. steel, glass etc.)
    mapping (string => Batch[]) private listOfBatches; //(name of material from 'listOfMaterials' => array of 'Batch' to store all batches related to the same name of material)
    
    mapping (uint => supplier[]) private supplyChain; // (assignementId -> string of all previous material owners)
    
    address[] private allContractorsAddresses; // array to store addresses of all contractors to be able later to loop through them and retrieve contractor's name from mapping 'listOfContractors'
    mapping (address => string) private listOfContractors; //(contractor's address => contractor's name)
    
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
    
    
    function generalInfo () public view returns (string memory generalInformation) {
        string memory developerAddr_str = Strings.toHexString(Developer);
        string memory buildingAddr_str = Strings.toHexString(BuildingAddress);
        generalInformation = string(abi.encodePacked( "(Building's Name: ", " -> ", BuildingName, " ) ", "(Building's Address: ", " -> ", buildingAddr_str, " ) ", "(Developer's Address: ", " -> ", developerAddr_str , " ) \n" ));
        return generalInformation;
    }
    
    
    mapping (address => string) public BatchCertificate; //(material batch contract address -> hash of certificate). It will be used to retrive certificate
    


    // function to see all materil names assigned to the building (i.e. steel, glass, timber etc.)
    function showListOfMaterials () public view returns (string memory materialsList ) {
        materialsList = ":\n";
        for (uint i=0; i<listOfMaterials.length-1; i++) {
            materialsList = string(abi.encodePacked(materialsList, listOfMaterials[i], ",\n"));
        }
        materialsList = string(abi.encodePacked(materialsList, listOfMaterials[listOfMaterials.length-1]));
        return materialsList;
    }


    // function allowing public to see all batches of particular material (e.g. steel) assigned to the building and find address and 'assignementId' for batch of interest
    function showOverviewOfMaterial (string memory material) public view returns  (string memory batchesList) { 
        //https://www.cloudhadoop.com/solidity-mapping-check-object-exists/ 
        require((listOfBatches[material].length > 0) == true, "Please try again as requested material was not found");         
        batchesList = ":\n";
        string memory id_str;
        string memory contract_str;
        string memory quantity_str; 
        string memory unit_str;
        for (uint i=0; i<listOfBatches[material].length; i++) {
            id_str = Strings.toString(listOfBatches[material][i].assignementId);
            contract_str = Strings.toHexString(listOfBatches[material][i].batchContractAddress);
            quantity_str = Strings.toString(listOfBatches[material][i].quantityAssigned);
            unit_str = listOfBatches[material][i].quantityUnit;
            batchesList = string(abi.encodePacked( batchesList, " ( ", contract_str , " -> ", quantity_str , unit_str, " -> ", id_str,   " ) \n" ));  //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
        }
        return batchesList;
        
    }

    // function which allows public to see whole supply chain of the material assigned at particular 'assignementId'
    function showSupplyChain (uint assignId) public view returns (string memory chainOfSupply) {
        require((supplyChain[assignId].length > 0) == true, "Please try again as requested batch address was not found");
        chainOfSupply = ":\n";
        string memory  supplier_address_str;
        string memory supplier_name;
        
        for (uint i=0; i<supplyChain[assignId].length; i++) {
            supplier_address_str = Strings.toHexString(supplyChain[assignId][i].supplierAddress);
            supplier_name = supplyChain[assignId][i].supplierName;
            
            chainOfSupply = string(abi.encodePacked( chainOfSupply, " ( ", supplier_address_str, " -> ", supplier_name , " ) \n" ));  //https://stackoverflow.com/questions/47129173/how-to-convert-uint-to-string-in-solidity
        }
        
        return chainOfSupply;
    } 

    // function allowing public to see all contractors registered on the building of interest
    function showAllRegisteredContractors() public view returns (string memory allContractors) {
        allContractors = ":\n";
        string memory  contractor_address_str;
        string memory contractor_name;
        for (uint i=0; i<allContractorsAddresses.length; i++) {
           contractor_address_str = Strings.toHexString(allContractorsAddresses[i]);
           contractor_name = listOfContractors[allContractorsAddresses[i]];
           allContractors = string(abi.encodePacked( allContractors, " ( ", contractor_address_str , " -> ", contractor_name , " ) \n" ));
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
    function assignMaterial (string memory material, address batchAddress, uint quantity, string memory unit, supplier[] memory chain) public onlyByRegisteredContractor disabledContract { 
        
        if (listOfBatches[material].length == 0) { //check whether material name already exists
            listOfMaterials.push(material);
        }
        
        Batch memory b;
        b.assignementId = assignement_number;
        b.batchContractAddress = batchAddress;
        b.quantityAssigned = quantity;
        b.quantityUnit = unit;
        listOfBatches[material].push(b);
        
        for (uint i=0; i<chain.length; i++) {
            supplyChain[assignement_number].push(chain[i]);
        }

        //it might be needed or not depending on  what is passed from contractor side contract
        supplier memory s;
        s.supplierAddress = msg.sender;
        s.supplierName = listOfContractors[msg.sender];
        supplyChain[assignement_number].push(s);
        
        assignement_number++;
    }


    modifier onlyByRegisteredContractor() {
        require(bytes(listOfContractors[msg.sender]).length != 0, "Can only be executed by the registered Contractor" );
        _;
    }


//============================================================================================================================

    
    //function for disabling active function of the contract and allowing onlyew view function to be accessible
    //this function is called from parent factory contract only by developer of this building
    function disableOrEnableContract () external {
        require(msg.sender == factoryContractAddress, "Only factory contract can call this function");
        contractIsDisabled = !contractIsDisabled;
    }
    
    modifier disabledContract () {
        require(contractIsDisabled == false, "Contract has been disabled");
        _;
    }

}    
