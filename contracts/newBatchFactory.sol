// SPDX-License-Identifier: UNLICENSED

pragma solidity >=0.8.00 <0.9.0;

import "./newBatch.sol";


// suggestion on factory inmplementation taked from here: https://blog.logrocket.com/cloning-solidity-smart-contracts-factory-pattern/
contract newBatchFactory { 
    
    // this struct is toring two array of material batches. One array represents batches which are still onwed by manufactiurer (i.e. they have not been sold)
    // and second array represents batches which have already been fully sold by the manufacturer
    struct materialBatches {
        bool exist;
        address[] ownedByManufacturer;
        address[] fullySoldFromManufacturer;
    }
    
    //this mapping stores batches under relevant key which is name of material (for example steel ect.)
    mapping (string => materialBatches) allMaterialBatchContracts;
    string[] private allMaterials;
    address private manufacturer;
    string public manufacturerName;
    bool public contractEnabled = true;

    
    // constructor records address of the manufacturer. Each factory contract is only supposed to be managed by the same one manufacturer
    // to make one factory contract store data on batch contracts created only for one manufacturer so that manufacturer and public can easily
    // retrieve all batches mroduced by this manufacturer and to reduce size of stored data in one factory contract (as otherwise 
    //it would have recorded to many transactions from different manufacturers)
    constructor () {
        manufacturer = msg.sender;
    } 

    modifier onlyByManufacturer() {
        require(msg.sender == manufacturer, "This functionality may only be used by the manufacturer who deployed this contract");
        _;
    }


    modifier contract_Enabled() {
        require(contractEnabled == true, "This factory contract has been disabled");
        _;
    }

    modifier manufacturerNameNotEmpty() {
         require(bytes(manufacturerName).length != 0, "Provide manufacturer name");
        _;
    }

    //option for manufacture to disable this factory contract if there (is need to)
    function disableOrEnableFactoryContract() public onlyByManufacturer {
        contractEnabled = !contractEnabled;
    }
    
    //recording or updating manufacturer's name
    function recordNameOfManufacturer(string memory name) public onlyByManufacturer contract_Enabled {
        manufacturerName = name;
    }


    // function to create new building contract. It is accessable to everybody and 'msg.sender' is recorded as developer bioth here and in relevant building contract
    function createNewBatch (string memory materialName, uint quantity, string memory quantityUnit) public onlyByManufacturer contract_Enabled  manufacturerNameNotEmpty {

        address newInstance = address(new newBatch(msg.sender, manufacturerName, materialName, quantity, quantityUnit));

        if (allMaterialBatchContracts[materialName].exist) {
             allMaterialBatchContracts[materialName].ownedByManufacturer.push(newInstance);  
        } else {
            materialBatches memory m;
            address[] memory temp = new address[](1);
            temp[0] = newInstance;
            m.exist = true;
            m.ownedByManufacturer = temp;
            allMaterialBatchContracts[materialName] = m;
            allMaterials.push(materialName);
        }  
    }

    //private view function to find index number of material batch contract sought
    //used by below 'materialFullySoldFromManufacturer' function
    function findIndex (string memory materialName, address batchAddress) private view returns (int256 indexNo) {
        indexNo = -1;
        for (uint i = 0; i<allMaterialBatchContracts[materialName].ownedByManufacturer.length; i++) {
            if (allMaterialBatchContracts[materialName].ownedByManufacturer[i] == batchAddress) {
                indexNo = int256(i);
                break;
            }
        }
        return indexNo;
    }

    //private view function to check whether of material batch contract sought is already recorded in array of sold materials
    //used by below 'materialFullySoldFromManufacturer' function
    function checkIfInSold (string memory materialName, address batchAddress) private view returns (bool answer) {
        answer = false;
        for (uint i = 0; i<allMaterialBatchContracts[materialName].fullySoldFromManufacturer.length; i++) {
            if (allMaterialBatchContracts[materialName].fullySoldFromManufacturer[i] == batchAddress) {
                answer = true;
                break;
            }
        }
        return answer;

    }

    //function which allows to move contract address of already fully sold batch of material to the relevant array
    //it is called externally from contract of relevant batch material once manufacturer has soll all its share in this contract 
    function materialFullySoldFromManufacturer (string memory materialName, address batchAddress) external {
        int256 indexNo = findIndex(materialName, batchAddress);
        if (indexNo >= 0) {
            uint index = uint(indexNo);
            allMaterialBatchContracts[materialName].fullySoldFromManufacturer.push(batchAddress);
            allMaterialBatchContracts[materialName].ownedByManufacturer[index] = allMaterialBatchContracts[materialName].ownedByManufacturer[allMaterialBatchContracts[materialName].ownedByManufacturer.length - 1];
            allMaterialBatchContracts[materialName].ownedByManufacturer.pop();
        } else if (! checkIfInSold(materialName, batchAddress) ) {
            allMaterialBatchContracts[materialName].fullySoldFromManufacturer.push(batchAddress);
        }
    }

    //showing all material names recorded by manufacturer (i.e. steel, stainless steel etc.)
    function showListOfMaterialsManufacturer() public view returns (string[] memory) {
        return allMaterials;
    }

    // showing all yet unsold by manufacturer material batches
    function showAllUnsoldBatchesOfMaterialManufacturer(string memory material) public view returns (address[] memory) {
        require(allMaterialBatchContracts[material].exist == true, "Entered material does not exist");
        return allMaterialBatchContracts[material].ownedByManufacturer;
    }
    // showing all already sold by manufacturer material batches
    function showAllSoldBatchesOfMaterialManufacturer(string memory material) public view returns (address[] memory) {
       require(allMaterialBatchContracts[material].exist == true, "Entered material does not exist");
       return allMaterialBatchContracts[material].fullySoldFromManufacturer;
    }
}