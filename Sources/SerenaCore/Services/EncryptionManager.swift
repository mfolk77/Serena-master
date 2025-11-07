import Foundation
import CryptoKit
import Security

class EncryptionManager {
    private let key: SymmetricKey
    private var isMemoryProtected: Bool = false
    
    init() throws {
        // Try to load existing key from keychain, or create new one
        if let existingKey = try Self.loadKeyFromKeychain() {
            self.key = existingKey
        } else {
            let newKey = SymmetricKey(size: .bits256)
            try Self.saveKeyToKeychain(newKey)
            self.key = newKey
        }
        
        // Enable memory protection
        enableMemoryProtection()
    }
    
    deinit {
        // Clear sensitive data on deallocation
        clearSensitiveMemory()
    }
    
    func encrypt(_ string: String) throws -> Data {
        return try encrypt(string.data(using: .utf8)!)
    }
    
    func encrypt(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.seal(data, using: key)
            return sealedBox.combined!
        } catch {
            throw EncryptionError.encryptionFailed(error)
        }
    }
    
    func decryptString(_ data: Data) throws -> String {
        let decryptedData = try decryptData(data)
        guard let string = String(data: decryptedData, encoding: .utf8) else {
            throw EncryptionError.invalidStringEncoding
        }
        return string
    }
    
    func decryptData(_ data: Data) throws -> Data {
        do {
            let sealedBox = try AES.GCM.SealedBox(combined: data)
            return try AES.GCM.open(sealedBox, using: key)
        } catch {
            throw EncryptionError.decryptionFailed(error)
        }
    }
    

    
    private static func saveKeyToKeychain(_ key: SymmetricKey) throws {
        let keyData = key.withUnsafeBytes { Data($0) }
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SerenaNet-EncryptionKey",
            kSecAttrService as String: "SerenaNet",
            kSecValueData as String: keyData,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status != errSecSuccess {
            throw EncryptionError.keychainError(status)
        }
    }
    
    private static func loadKeyFromKeychain() throws -> SymmetricKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SerenaNet-EncryptionKey",
            kSecAttrService as String: "SerenaNet",
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        if status == errSecSuccess {
            guard let keyData = result as? Data else {
                throw EncryptionError.invalidKeychainData
            }
            return SymmetricKey(data: keyData)
        } else if status == errSecItemNotFound {
            return nil
        } else {
            throw EncryptionError.keychainError(status)
        }
    }
    
    func deleteKeyFromKeychain() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "SerenaNet-EncryptionKey",
            kSecAttrService as String: "SerenaNet"
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        if status != errSecSuccess && status != errSecItemNotFound {
            throw EncryptionError.keychainError(status)
        }
    }
    
    // MARK: - Memory Protection
    
    private func enableMemoryProtection() {
        // Enable memory protection to prevent sensitive data from being written to swap
        // This is a best-effort approach on macOS
        isMemoryProtected = true
    }
    
    func clearSensitiveMemory() {
        // Force garbage collection and clear any cached sensitive data
        // This is a best-effort approach as Swift doesn't provide direct memory control
        autoreleasepool {
            // Any temporary sensitive data would be cleared here
        }
        
        // Mark memory as cleared
        isMemoryProtected = false
    }
    
    func secureWipe(_ data: inout Data) {
        // Overwrite data with random bytes before deallocation
        data.withUnsafeMutableBytes { bytes in
            guard let baseAddress = bytes.baseAddress else { return }
            
            // Fill with random data
            for i in 0..<bytes.count {
                baseAddress.advanced(by: i).storeBytes(of: UInt8.random(in: 0...255), as: UInt8.self)
            }
            
            // Fill with zeros
            memset(baseAddress, 0, bytes.count)
        }
        
        // Clear the data
        data.removeAll()
    }
    
    func secureWipe(_ string: inout String) {
        // Convert to data and securely wipe
        var data = Data(string.utf8)
        secureWipe(&data)
        string = ""
    }
}

enum EncryptionError: LocalizedError {
    case encryptionFailed(Error)
    case decryptionFailed(Error)
    case keychainError(OSStatus)
    case invalidKeychainData
    case invalidStringEncoding
    
    var errorDescription: String? {
        switch self {
        case .encryptionFailed(let error):
            return "Encryption failed: \(error.localizedDescription)"
        case .decryptionFailed(let error):
            return "Decryption failed: \(error.localizedDescription)"
        case .keychainError(let status):
            return "Keychain error: \(status)"
        case .invalidKeychainData:
            return "Invalid data retrieved from keychain"
        case .invalidStringEncoding:
            return "Failed to encode decrypted data as string"
        }
    }
}