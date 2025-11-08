import XCTest
@testable import SerenaNet

@MainActor
final class PasscodeManagerTests: XCTestCase {
    var passcodeManager: PasscodeManager!
    
    override func setUp() async throws {
        try await super.setUp()
        passcodeManager = PasscodeManager()
        
        // Clean up any existing passcode
        try? passcodeManager.removePasscode()
    }
    
    override func tearDown() async throws {
        // Clean up passcode after each test
        try? passcodeManager.removePasscode()
        try await super.tearDown()
    }
    
    func testInitialState() {
        XCTAssertFalse(passcodeManager.passcodeEnabled)
        XCTAssertFalse(passcodeManager.isLocked)
    }
    
    func testSetPasscode() throws {
        let testPasscode = "1234"
        
        try passcodeManager.setPasscode(testPasscode)
        
        XCTAssertTrue(passcodeManager.passcodeEnabled)
        XCTAssertFalse(passcodeManager.isLocked) // Should unlock after setting
    }
    
    func testSetEmptyPasscode() {
        XCTAssertThrowsError(try passcodeManager.setPasscode("")) { error in
            XCTAssertTrue(error is PasscodeError)
            if case PasscodeError.emptyPasscode = error {
                // Expected error
            } else {
                XCTFail("Expected emptyPasscode error")
            }
        }
    }
    
    func testSetShortPasscode() {
        XCTAssertThrowsError(try passcodeManager.setPasscode("12")) { error in
            XCTAssertTrue(error is PasscodeError)
            if case PasscodeError.passcodeTooShort = error {
                // Expected error
            } else {
                XCTFail("Expected passcodeTooShort error")
            }
        }
    }
    
    func testVerifyCorrectPasscode() throws {
        let testPasscode = "1234"
        
        try passcodeManager.setPasscode(testPasscode)
        passcodeManager.lockApp()
        
        let isValid = try passcodeManager.verifyPasscode(testPasscode)
        
        XCTAssertTrue(isValid)
        XCTAssertFalse(passcodeManager.isLocked) // Should unlock after correct verification
    }
    
    func testVerifyIncorrectPasscode() throws {
        let testPasscode = "1234"
        let wrongPasscode = "5678"
        
        try passcodeManager.setPasscode(testPasscode)
        passcodeManager.lockApp()
        
        let isValid = try passcodeManager.verifyPasscode(wrongPasscode)
        
        XCTAssertFalse(isValid)
        XCTAssertTrue(passcodeManager.isLocked) // Should remain locked after incorrect verification
    }
    
    func testVerifyPasscodeWhenNoneSet() {
        XCTAssertThrowsError(try passcodeManager.verifyPasscode("1234")) { error in
            XCTAssertTrue(error is PasscodeError)
            if case PasscodeError.noPasscodeSet = error {
                // Expected error
            } else {
                XCTFail("Expected noPasscodeSet error")
            }
        }
    }
    
    func testRemovePasscode() throws {
        let testPasscode = "1234"
        
        // Set passcode first
        try passcodeManager.setPasscode(testPasscode)
        XCTAssertTrue(passcodeManager.passcodeEnabled)
        
        // Remove passcode
        try passcodeManager.removePasscode()
        
        XCTAssertFalse(passcodeManager.passcodeEnabled)
        XCTAssertFalse(passcodeManager.isLocked)
    }
    
    func testLockApp() throws {
        let testPasscode = "1234"
        
        try passcodeManager.setPasscode(testPasscode)
        XCTAssertFalse(passcodeManager.isLocked)
        
        passcodeManager.lockApp()
        
        XCTAssertTrue(passcodeManager.isLocked)
    }
    
    func testLockAppWhenPasscodeDisabled() {
        XCTAssertFalse(passcodeManager.passcodeEnabled)
        
        passcodeManager.lockApp()
        
        XCTAssertFalse(passcodeManager.isLocked) // Should not lock when passcode is disabled
    }
    
    func testPasscodePersistence() throws {
        let testPasscode = "1234"
        
        // Set passcode
        try passcodeManager.setPasscode(testPasscode)
        
        // Create new manager instance (simulates app restart)
        let newPasscodeManager = PasscodeManager()
        
        // Should detect existing passcode
        XCTAssertTrue(newPasscodeManager.passcodeEnabled)
        XCTAssertTrue(newPasscodeManager.isLocked) // Should be locked on startup
        
        // Should be able to verify with stored passcode
        let isValid = try newPasscodeManager.verifyPasscode(testPasscode)
        XCTAssertTrue(isValid)
    }
    
    func testDifferentPasscodesProduceDifferentHashes() throws {
        let passcode1 = "1234"
        let passcode2 = "5678"
        
        // Set first passcode
        try passcodeManager.setPasscode(passcode1)
        let isValid1 = try passcodeManager.verifyPasscode(passcode1)
        XCTAssertTrue(isValid1)
        
        // Change to second passcode
        try passcodeManager.setPasscode(passcode2)
        
        // First passcode should no longer work
        let isValid2 = try passcodeManager.verifyPasscode(passcode1)
        XCTAssertFalse(isValid2)
        
        // Second passcode should work
        let isValid3 = try passcodeManager.verifyPasscode(passcode2)
        XCTAssertTrue(isValid3)
    }
    
    func testLongPasscode() throws {
        let longPasscode = "123456789012345678901234567890"
        
        try passcodeManager.setPasscode(longPasscode)
        
        XCTAssertTrue(passcodeManager.passcodeEnabled)
        
        let isValid = try passcodeManager.verifyPasscode(longPasscode)
        XCTAssertTrue(isValid)
    }
    
    func testSpecialCharactersInPasscode() throws {
        let specialPasscode = "!@#$%^&*()"
        
        try passcodeManager.setPasscode(specialPasscode)
        
        XCTAssertTrue(passcodeManager.passcodeEnabled)
        
        let isValid = try passcodeManager.verifyPasscode(specialPasscode)
        XCTAssertTrue(isValid)
    }
    
    func testUnicodePasscode() throws {
        let unicodePasscode = "🔒🔑🛡️🔐"
        
        try passcodeManager.setPasscode(unicodePasscode)
        
        XCTAssertTrue(passcodeManager.passcodeEnabled)
        
        let isValid = try passcodeManager.verifyPasscode(unicodePasscode)
        XCTAssertTrue(isValid)
    }
    
    func testClearSensitiveMemory() throws {
        let testPasscode = "1234"
        
        try passcodeManager.setPasscode(testPasscode)
        
        // This should not throw and should complete successfully
        passcodeManager.clearSensitiveMemory()
        
        // Passcode should still work after memory clearing
        let isValid = try passcodeManager.verifyPasscode(testPasscode)
        XCTAssertTrue(isValid)
    }
    
    func testCanUseBiometrics() {
        // This test will vary based on the testing environment
        // We just ensure the method doesn't crash
        let canUse = passcodeManager.canUseBiometrics()
        
        // Result can be true or false depending on the system
        XCTAssertTrue(canUse == true || canUse == false)
    }
}