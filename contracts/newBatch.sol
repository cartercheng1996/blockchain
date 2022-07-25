// SPDX-License-Identifier: UNLICENSED

//6452-22T2 Assignment2-part2 group SC9

// Author : E. Omer Gul
//co-authored: Aliaksei Beraziuk



//README (main usage explanation):
// This is a contract for a material batch
//Each batch contract records all information on ownership of any share of material from this batch. for example:
//- if 100 tonns of steel were produced as one batch by manufacturer
//-before starting to sell any material from this batch manufacturer has to record hash of the conformance certificate for this batch (using reverse oracle)
//this has will be later used by oracle to return proven to be authentic conformace certificate file (e.g. PDF) to the user;
//- manufacturer sells 30 tonns to contractor1, 30 tonns to contractor2 and 40tonns to contractor3 (all this is recorded)
//- then all contractors can resell whole or share of their owned material from this batch (this as well will be recorded)
//- eventually final contractor in the chain will call "assignTo' funcrtion (below) from this batch with will make a call to "newBuilding" contract
//and pass all relevant information about batch and previous owners of this share of the bacth to the "newBuilding" contract where public will be able to access this info
//further details of functionality are described in below comments to the functions



pragma solidity >=0.8.00 <0.9.0;



contract newBatch {

    // structure for recording information about every supplier in supply chain of the material assigned to the building
    struct supplier {
        address supplierAddress;
        string supplierName;
    }

    struct currentOwnershipInfo {
        uint quantityofMaterialCurrentlyOwned;
        supplier[] suppliersChain; // owners of this contract
    }
    mapping(address => currentOwnershipInfo) private currentOwnwers; // currenct owners of this contract
    address[] private allCurrentOwnersAddresses;

    
    //auxiliary structure created only for using in 'showAllCurrentOwnership' function
    struct currentOwnershipShow {
        address supplierAddress;
        string supplierName;
        uint quantityofMaterialCurrentlyOwned;
    }
    

    bool private contractIsDisabled = false; //variable to disable execution function in this contract but to leave view options 
    string private materialType; // ex brick, concrete, wood etc.
    uint private initialBatchMaterialQuantity;
    uint private unassignedQuantity; // ex :200, 10
    string private quantityUnit; // ex: kg, ton, m3
    address private manufacturer; //records address of manufacturer
    address private parentFactoryContractAddress; // used once to update parent factory contract with information that manufacturer has sold all material from this batch via "transfer" function
    address[] private allBuildingToWhichAssigned; // which buildings has this contract been assigned to 
    address private thisBatchContractAddress;
    
    string public certificate_hash; // used to verify off chain cerificate



    constructor (address manufacturerAddress, string memory manufacturerName, string memory materialName, uint quantity, string memory unit ) {
        allCurrentOwnersAddresses.push(manufacturerAddress);
        
        currentOwnwers[manufacturerAddress].quantityofMaterialCurrentlyOwned = quantity;

        supplier memory sup;
        sup.supplierAddress = manufacturerAddress;
        sup.supplierName = manufacturerName;
        
        currentOwnwers[manufacturerAddress].suppliersChain.push(sup);
        
        unassignedQuantity = quantity;
        initialBatchMaterialQuantity = quantity;
        quantityUnit = unit;
        materialType = materialName;
        manufacturer = manufacturerAddress;

        thisBatchContractAddress = address(this);
        parentFactoryContractAddress = msg.sender;
    }

    
    //modifiers with self-explanatory names
    modifier isOwner() {
        require(currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned > 0, "You do not own any material in this batch contract" );
        _;
    }

    modifier onlyByManufacturer() {
        require(msg.sender == manufacturer, "This function can be executed only by manufacturer of this material batch");
        _;
    }

    modifier notDisabled() {
        require(contractIsDisabled == false, "This functionality has been disabled");
        _;
    }


    //private vew function required for and used in "assignTo" function below
    function prepareSuppliersChainForSend(address sender) private view returns (address[] memory, string[] memory) {
        address[] memory suppliersAddr = new address[](currentOwnwers[sender].suppliersChain.length);
        string[] memory suppliersName = new string[](currentOwnwers[sender].suppliersChain.length);
        for (uint i=0; i<currentOwnwers[sender].suppliersChain.length; i++) {
            suppliersAddr[i] = currentOwnwers[sender].suppliersChain[i].supplierAddress;
            suppliersName[i] = currentOwnwers[sender].suppliersChain[i].supplierName;
        }
        return (suppliersAddr, suppliersName);
    }  
    
    
    
    //private view function required for and used in 'transfer' function below
    function findOwnerId(address soughtOwner) private view returns (uint i) {
        for (i=0; i<allCurrentOwnersAddresses.length; i++) {
            if (allCurrentOwnersAddresses[i] == soughtOwner) {
                return i;
            }
        }
    }

    
    
//==================================================PUBLIC FUNCTIONS===========================================================================   

    //view function to return general information about the batch of material
    function batchGeneralInfo () public view returns (address Contract_Address, uint Initial_Quantity, uint Unssigned_Quantity, string memory Unit_Of_Quantity) {
        
        Contract_Address = thisBatchContractAddress;
        Initial_Quantity = initialBatchMaterialQuantity;
        Unssigned_Quantity = unassignedQuantity;
        Unit_Of_Quantity = quantityUnit;
        
        return (Contract_Address, Initial_Quantity, Unssigned_Quantity, Unit_Of_Quantity);
    }


    //record hash of conformance certificate. It can be done and has to be done only before first sell (i.e. while manufacturer owns all material
    function provideCertificateHash(string memory hash) public onlyByManufacturer {
        certificate_hash = hash;
    }

    

    // this function assigns material to the building and provides all required data for record in building contract
    function assignTo(address buildingAddr, uint quantity) public isOwner notDisabled{
        require(currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned >= quantity, "You own insufficient quantity of material for this transaction" );
        
        (address[] memory supplAddresses, string[] memory supplNames) = prepareSuppliersChainForSend(msg.sender);
 
        currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned -= quantity;
        (bool success, bytes memory result) = buildingAddr.call(abi.encodeWithSignature("assignMaterial(string,uint256,string,address[],string[],address)", materialType,  quantity, quantityUnit, supplAddresses, supplNames, thisBatchContractAddress));   //,     
                
        result = result;
        require(success == true, "Material assignment failure. Possible reason: you are not registered contractor on the building you assign material to");

        allBuildingToWhichAssigned.push(buildingAddr);
     
        unassignedQuantity -= quantity;
        if (unassignedQuantity == 0) {
            contractIsDisabled = true;
        }

        //checking if seller is to be deleted from ownership list
        if (currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned == 0) {
            if (msg.sender == manufacturer) {
                (success, result) = parentFactoryContractAddress.call(abi.encodeWithSignature("materialFullySoldFromManufacturer(string,address)", materialType, thisBatchContractAddress));
                result = result;
                require(success == true, "External call to parent factory contract failure");
            }
            delete currentOwnwers[msg.sender];
            uint sellerId = findOwnerId(msg.sender);
            allCurrentOwnersAddresses[sellerId] = allCurrentOwnersAddresses[allCurrentOwnersAddresses.length - 1];
            allCurrentOwnersAddresses.pop();
        }  
    }


    // function to show all current owners' addresses, their names and quantity of material owned
    function showAllCurrentOwnership() public view isOwner notDisabled returns (currentOwnershipShow[] memory) {
        currentOwnershipShow[] memory listOfCurrentOwners = new currentOwnershipShow[](allCurrentOwnersAddresses.length);
        
        for (uint i=0; i<allCurrentOwnersAddresses.length; i++) {
            currentOwnershipShow memory co;
            uint lengthOfSupplChain = currentOwnwers[allCurrentOwnersAddresses[i]].suppliersChain.length;
            co.supplierAddress = allCurrentOwnersAddresses[i];
            co.supplierName = currentOwnwers[allCurrentOwnersAddresses[i]].suppliersChain[lengthOfSupplChain - 1].supplierName;
            co.quantityofMaterialCurrentlyOwned = currentOwnwers[allCurrentOwnersAddresses[i]].quantityofMaterialCurrentlyOwned;
            listOfCurrentOwners[i] = co;
        }
        return listOfCurrentOwners;
    }


    // function to show list of all building to which this batch of material will have been assigned to
    function showAllBuildingsAssignedTo() public view returns (address[] memory) {
        return allBuildingToWhichAssigned;
    }


    //function to disable or enable butch contract. It can be used only by manufacturer and only while manufacturer owns 100% of this batch contract
    function disable_enableContract() public onlyByManufacturer {
        require(allCurrentOwnersAddresses.length == 1 && allCurrentOwnersAddresses[0] == manufacturer, "Error: Contract can not be disabled as as manufacturer does not longer own 100% of the material from this batch");
        contractIsDisabled = !contractIsDisabled;
    }



    //function to show supply chain for portion of batch for requested owner
    function showSupplyChainForCurrentOwner(address ownerAddr ) public view returns (supplier[] memory) {
        require(currentOwnwers[ownerAddr].quantityofMaterialCurrentlyOwned > 0, "Provided address is not found amongst current owners");
        return currentOwnwers[ownerAddr].suppliersChain;
    }




    //transfer function allows current owner of the material from this batch to stransfer material's ownership to another contractor
    //seller has to have sufficirnt materil owned in this batch and can not re-sell to themselves as checked by 'require' below
    function transfer(uint quantity, address buyerAddr, string memory buyerName) public isOwner notDisabled{
        require(currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned >= quantity, "You own insufficient quantity of material for this transaction" );
        require(msg.sender != buyerAddr, "Error: byer and seller addresses are identical. You cannot re-sell material to yourself");
        require(bytes(certificate_hash).length > 0, "Hash of conformance certificate has to be provided before transfer operation");
        
        currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned -= quantity;
        
        supplier memory sup;
        sup.supplierAddress = buyerAddr;
        sup.supplierName = buyerName;
        
        if (currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned > 0) {
            //if contractor already bought material from this batch preiously (maybe from another seller)
            
            if (quantity > currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned) {
                //if currenly bought quantity is more than already owned from this batch then take chain history from current purchase
                currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned = currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned + quantity;
                currentOwnwers[buyerAddr].suppliersChain = currentOwnwers[msg.sender].suppliersChain;
                currentOwnwers[buyerAddr].suppliersChain.push(sup);
            } else { //if currenly bought quantity is less than already owned from this batch then leave supply chain history unchanged and just add new quantity
                currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned += quantity;
            }
        } else { // contractor buying material from this batch does not have material from this batch recorded for them
            currentOwnwers[buyerAddr].quantityofMaterialCurrentlyOwned = quantity;
            currentOwnwers[buyerAddr].suppliersChain = currentOwnwers[msg.sender].suppliersChain;
            currentOwnwers[buyerAddr].suppliersChain.push(sup);
            allCurrentOwnersAddresses.push(buyerAddr);
        }   

        //checking if seller is to be deleted from ownership list
        if (currentOwnwers[msg.sender].quantityofMaterialCurrentlyOwned == 0) {
            if (msg.sender == manufacturer) {
                (bool success, bytes memory result) = parentFactoryContractAddress.call(abi.encodeWithSignature("materialFullySoldFromManufacturer(string,address)", materialType, thisBatchContractAddress));
                result = result;
                require(success == true, "External call to parent factory contract failure");
            }
            delete currentOwnwers[msg.sender];
            uint sellerId = findOwnerId(msg.sender);
            allCurrentOwnersAddresses[sellerId] = allCurrentOwnersAddresses[allCurrentOwnersAddresses.length - 1];
            allCurrentOwnersAddresses.pop();
        }  

    } 
}

