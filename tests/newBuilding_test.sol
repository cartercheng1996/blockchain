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
    address acc0 ;
    address acc1 ;
    address acc2 ;
    address acc3 ;
    address acc4 ;
    newBuilding newBuilding_test;

    /// 'beforeAll' runs before all other tests
    /// More special functions are: 'beforeEach', 'beforeAll', 'afterEach' & 'afterAll'
    function beforeAll() public {
        // <instantiate contract>
        Assert.equal(uint(1), uint(1), "1 should be equal to 1");
        acc0 = TestsAccounts.getAccount (0) ; // Initiate account variables
        acc1 = TestsAccounts.getAccount (1) ;
        acc2 = TestsAccounts.getAccount (2) ;
        acc3 = TestsAccounts.getAccount (3) ;
        acc4 = TestsAccounts.getAccount (4) ;
    }

    /// Testing newBuilding constructor, and a few public functions.
    function checkConstructorSuccess() public {
        // Initilised new building contract by calling constuctor
        newBuilding_test = new newBuilding(acc0,"testBuilding");
        Assert.ok(true , "Method execution should be ok");
        // Testing the public function get general info directly after calling the constructor.
        (string memory Building_Name, address Building_Address, address Developer_Address) = newBuilding_test.generalInfo();
        Assert.equal("testBuilding", Building_Name, "should be same return string");
        Assert.equal(address(newBuilding_test), Building_Address, "should be same return Address");
        Assert.equal(address(acc0), Developer_Address, "should be same return Address");
        // thes list material function when it is empty list just after calling constructor.
        string[] memory listMaterials = newBuilding_test.showListOfMaterials();
        string[1] memory listMaterialsAns = [''];
        Assert.equal(listMaterialsAns[0], listMaterials[0], "should be same return string");

    }
    

    /// This will cause error if addContractor modifier onlyByDeveloper has msg.sender == Developer, modify to tx.origin == Developer
    /// This is to test if addContractor function can add another contractor
    /// #sender: account-0
    function checkaddContractorSuccess() public {
        // Use 'Assert' methods: https://remix-ide.readthedocs.io/en/latest/assert_library.html
        // Assert.ok(2 == 2, 'should be true');
        // Assert.greaterThan(uint(2), uint(1), "2 should be greater than to 1");
        // Assert.lesserThan(uint(2), uint(3), "2 should be lesser than to 3");
        string memory str1 = "testConstructor1";
        newBuilding_test.addContractor(acc1,str1);
    }



    function checkSuccess2() public pure returns (bool) {
        // Use the return value (true or false) to test the contract
        return true;
    }
    

    /// Custom Transaction Context: https://remix-ide.readthedocs.io/en/latest/unittesting.html#customization
    /// #sender: account-1
    /// #value: 100
    function checkSenderAndValue() public payable {
        // account index varies 0-9, value is in wei
        Assert.equal(msg.sender, TestsAccounts.getAccount(1), "Invalid sender");
        Assert.equal(msg.value, 100, "Invalid value");
    }
}
    