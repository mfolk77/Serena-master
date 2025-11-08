import XCTest
@testable import SerenaNet

final class EncryptionManagerTests: XCTestCase {
    var encryptionManager: EncryptionManager!
    
    override func setUp() async throws {
        try await super.setUp()
        encryptionManager = try EncryptionManager()
    }
    
    override func tearDown() async throws {
        // Clean up keychain
        try encryptionManager.deleteKeyFromKeychain()
        try await super.tearDown()
    }
    
    func testStringEncryptionDecryption() throws {
        let originalString = "Hello, this is a test message!"
        
        let encryptedData = try encryptionManager.encrypt(originalString)
        let decryptedString = try encryptionManager.decryptString(encryptedData)
        
        XCTAssertEqual(originalString, decryptedString)
        XCTAssertNotEqual(originalString.data(using: .utf8)!, encryptedData)
    }
    
    func testDataEncryptionDecryption() throws {
        let originalData = "Test data for encryption".data(using: .utf8)!
        
        let encryptedData = try encryptionManager.encrypt(originalData)
        let decryptedData = try encryptionManager.decryptData(encryptedData)
        
        XCTAssertEqual(originalData, decryptedData)
        XCTAssertNotEqual(originalData, encryptedData)
    }
    
    func testEmptyStringEncryption() throws {
        let emptyString = ""
        
        let encryptedData = try encryptionManager.encrypt(emptyString)
        let decryptedString = try encryptionManager.decryptString(encryptedData)
        
        XCTAssertEqual(emptyString, decryptedString)
    }
    
    func testLargeDataEncryption() throws {
        let largeString = String(repeating: "A", count: 10000)
        
        let encryptedData = try encryptionManager.encrypt(largeString)
        let decryptedString = try encryptionManager.decryptString(encryptedData)
        
        XCTAssertEqual(largeString, decryptedString)
    }
    
    func testUnicodeEncryption() throws {
        let unicodeString = "Hello 🌍! Testing émojis and spëcial characters: 中文, العربية, русский"
        
        let encryptedData = try encryptionManager.encrypt(unicodeString)
        let decryptedString = try encryptionManager.decryptString(encryptedData)
        
        XCTAssertEqual(unicodeString, decryptedString)
    }
    
    func testKeyPersistence() throws {
        let testString = "Test key persistence"
        let encryptedData = try encryptionManager.encrypt(testString)
        
        // Create a new encryption manager (should load the same key from keychain)
        let newEncryptionManager = try EncryptionManager()
        let decryptedString = try newEncryptionManager.decryptString(encryptedData)
        
        XCTAssertEqual(testString, decryptedString)
    }
    
    func testInvalidDataDecryption() {
        let invalidData = Data([1, 2, 3, 4, 5])
        
        XCTAssertThrowsError(try encryptionManager.decryptString(invalidData)) { error in
            XCTAssertTrue(error is EncryptionError)
        }
    }
    
    func testDifferentKeysProduceDifferentResults() throws {
        let testString = "Same input, different keys"
        
        let encrypted1 = try encryptionManager.encrypt(testString)
        
        // Delete key and create new manager (will generate new key)
        try encryptionManager.deleteKeyFromKeychain()
        let newEncryptionManager = try EncryptionManager()
        let encrypted2 = try newEncryptionManager.encrypt(testString)
        
        // Same input with different keys should produce different encrypted data
        XCTAssertNotEqual(encrypted1, encrypted2)
        
        // But each should decrypt correctly with their respective keys
        let decrypted1 = try encryptionManager.decryptString(encrypted1)
        let decrypted2 = try newEncryptionManager.decryptString(encrypted2)
        
        XCTAssertEqual(decrypted1, testString)
        XCTAssertEqual(decrypted2, testString)
    }
    
    func testMemoryProtection() {
        // Test that memory protection methods don't crash
        encryptionManager.clearSensitiveMemory()
        
        // Should still be able to encrypt/decrypt after memory clearing
        let testString = "Memory protection test"
        
        XCTAssertNoThrow {
            let encrypted = try self.encryptionManager.encrypt(testString)
            let decrypted = try self.encryptionManager.decryptString(encrypted)
            XCTAssertEqual(testString, decrypted)
        }
    }
    
    func testSecureWipeData() {
        var testData = Data("Sensitive data to be wiped".utf8)
        let originalCount = testData.count
        
        XCTAssertGreaterThan(originalCount, 0)
        
        encryptionManager.secureWipe(&testData)
        
        XCTAssertEqual(testData.count, 0)
    }
    
    func testSecureWipeString() {
        var testString = "Sensitive string to be wiped"
        
        XCTAssertFalse(testString.isEmpty)
        
        encryptionManager.secureWipe(&testString)
        
        XCTAssertTrue(testString.isEmpty)
    }
    
    func testSecureWipeEmptyData() {
        var emptyData = Data()
        
        // Should not crash with empty data
        XCTAssertNoThrow {
            self.encryptionManager.secureWipe(&emptyData)
        }
        
        XCTAssertEqual(emptyData.count, 0)
    }
    
    func testSecureWipeEmptyString() {
        var emptyString = ""
        
        // Should not crash with empty string
        XCTAssertNoThrow {
            self.encryptionManager.secureWipe(&emptyString)
        }
        
        XCTAssertTrue(emptyString.isEmpty)
    }
}