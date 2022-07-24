// SPDX-License-Identifier: GPL-3.0
        
pragma solidity >=0.8.00 <0.9.0;

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

    function checkConstructorSuccess() public {
        string memory BuildingName = "testBuilding";
        newBuilding_test = new newBuilding(acc0,BuildingName);
        string memory buildingAddr_str = Strings.toHexString(address(newBuilding_test));
        string memory developerAddr_str = Strings.toHexString(address(acc0));
        Assert.ok(true , "Method execution should be ok");
        string memory res_str  = string(abi.encodePacked( "(Building's Name: ", " -> ", BuildingName, " ) ", "(Building's Address: ", " -> ", buildingAddr_str, " ) ", "(Developer's Address: ", " -> ", developerAddr_str , " ) \n" ));
        Assert.equal(newBuilding_test.generalInfo(), res_str, "should be yes");
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
    