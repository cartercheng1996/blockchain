// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.4.22 <0.9.0;

// This import is automatically injected by Remix
import "remix_tests.sol";

// This import is required to use custom transaction context
// Although it may fail compilation in 'Solidity Compiler' plugin
// But it will work fine in 'Solidity Unit Testing' plugin
import "remix_accounts.sol";
import "../contracts/newBuilding.sol";

// File name has to end with '_test.sol', this file can contain more than one testSuite contracts
contract testSuite {
    // Variables used to emulate different accounts
    address acc0;
    address acc1;
    address acc2;
    address acc3;
    address acc4;
    newBuilding newBuilding_test;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        Assert.equal(uint256(1), uint256(1), "1 should be equal to 1");
        acc0 = TestsAccounts.getAccount(0); // Initiate account variables
        acc1 = TestsAccounts.getAccount(1);
        acc2 = TestsAccounts.getAccount(2);
        acc3 = TestsAccounts.getAccount(3);
        acc4 = TestsAccounts.getAccount(4);
    }

    /// Testing newBuilding constructor, and a few public functions.
    function checkConstructorSuccess() public {
        // Initilised new building contract by calling constuctor
        newBuilding_test = new newBuilding(acc0, "testBuilding");
        Assert.ok(true, "Method execution should be ok");
        // Testing the public function get general info directly after calling the constructor.
        (
            string memory Building_Name,
            address Building_Address,
            address Developer_Address
        ) = newBuilding_test.generalInfo();
        Assert.equal(
            "testBuilding",
            Building_Name,
            "should be same return string"
        );
        Assert.equal(
            address(newBuilding_test),
            Building_Address,
            "should be same return Address"
        );
        Assert.equal(
            address(acc0),
            Developer_Address,
            "should be same return Address"
        );
        // test list material function when it is empty list just after calling constructor.
        string[] memory listMaterials = newBuilding_test.showListOfMaterials();
        string[1] memory listMaterialsAns = [""];
        Assert.equal(
            listMaterialsAns[0],
            listMaterials[0],
            "should be same return string"
        );
        // test showAllRegisteredContractors function when it is empty list just after calling constructor.
        newBuilding.tempContractor[] memory allContractor;
        allContractor = newBuilding_test.showAllRegisteredContractors();
        Assert.equal(
            allContractor.length,
            1,
            "Should be only one register contractor in array when it is just initilised"
        );
        Assert.equal(
            allContractor[0].name,
            "Developer",
            "should be same name as Developer"
        );
        Assert.equal(
            allContractor[0].addr,
            acc0,
            "should be same address as acc0"
        );
        // test showSupplyChain function when it is empty list just after calling constructor.
        newBuilding_test.showSupplyChain(1);
        Assert.ok(true, "Method execution should be ok");
        // test showOverviewOfMaterial with requested material was not found
        try newBuilding_test.showOverviewOfMaterial("steel"){
            Assert.ok(false , "Method execution should fail");
        } catch Error ( string memory reason ) {
            Assert.equal (reason , "Please try again as requested material was not found", "Failed with unexpected reason");
        } catch ( bytes memory /* lowLevelData */) {
            Assert.ok(false , "Failed unexpected");
        }
    }

    /// This is to test if addContractor function can only allow developer to call it
    /// #sender: account-1
    function checkaddContractorFailed() public {
        string memory str1 = "testConstructor1";
        try newBuilding_test.addContractor(acc0, str1){
            Assert.ok(false , "Method execution should fail");
        } catch Error ( string memory reason ) {
            Assert.equal (reason , "Can only be executed by the Developer", "Failed with unexpected reason");
        } catch ( bytes memory /* lowLevelData */) {
            Assert.ok(false , "Failed unexpected");
        }
    }



    /// This will cause error if addContractor modifier onlyByDeveloper has msg.sender == Developer, modify to tx.origin == Developer
    /// This is to test if addContractor function can add another contractor and showAllRegisteredContractors function
    /// #sender: account-0
    function checkaddContractorSuccess() public {
        string memory str1 = "testConstructor1";
        newBuilding_test.addContractor(acc1, str1);
        string memory str2 = "testConstructor2";
        newBuilding_test.addContractor(acc2, str2);
    }

    /// This is to test if addContractor function can avoid adding two same contrators
    /// #sender: account-0
    function checkaddContractorFailed2() public {
        string memory str1 = "testConstructor1";
        try newBuilding_test.addContractor(acc0, str1){
            Assert.ok(false , "Method execution should fail");
        } catch Error ( string memory reason ) {
            Assert.equal (reason , "Contractor is already registered", "Failed with unexpected reason");
        } catch ( bytes memory /* lowLevelData */) {
            Assert.ok(false , "Failed unexpected");
        }
    }

    /// This is to test if showContractor function can return value corretlly
    /// #sender: account-0
    function checkshowContractorsuccess() public {
        newBuilding.tempContractor[] memory allContractor;
        allContractor = newBuilding_test.showAllRegisteredContractors();
        Assert.equal(
            allContractor.length,
            3,
            "Should be 3 register contractor in array"
        );
        Assert.equal(
            allContractor[0].name,
            "Developer",
            "should be same name as Developer"
        );
        Assert.equal(
            allContractor[0].addr,
            acc0,
            "should be same address as acc0"
        );
        Assert.equal(
            allContractor[1].name,
            "testConstructor1",
            "should be same name as Developer"
        );
        Assert.equal(
            allContractor[1].addr,
            acc1,
            "should be same address as acc1"
        );

    }
    function checkassignMaterialSuccess() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }

}
