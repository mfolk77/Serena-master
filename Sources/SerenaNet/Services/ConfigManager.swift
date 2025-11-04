import Foundation
import SwiftUI

@MainActor
class ConfigManager: ObservableObject {
    @Published var userConfig: UserConfig = UserConfig.default
    
    private let dataStore: DataStore
    private let chatManager: ChatManager?
    private let passcodeManager: PasscodeManager
    private let userDefaults = UserDefaults.standard
    
    // First launch detection
    var isFirstLaunch: Bool {
        return !userDefaults.bool(forKey: "HasCompletedOnboarding")
    }
    
    init(chatManager: ChatManager? = nil, passcodeManager: PasscodeManager? = nil) {
        self.chatManager = chatManager
        self.passcodeManager = passcodeManager ?? PasscodeManager()
        
        do {
            self.dataStore = try DataStore()
        } catch {
            // For now, create a mock data store if initialization fails
            // In production, this should be handled more gracefully
            fatalError("Failed to initialize DataStore: \(error)")
        }
    }
    
    // MARK: - Configuration Management
    
    func loadConfiguration() {
        Task {
            do {
                userConfig = try await dataStore.loadUserConfig()
                applyTheme()
            } catch {
                print("Failed to load user configuration: \(error)")
                userConfig = UserConfig.default
            }
        }
    }
    
    func saveConfiguration() {
        Task {
            do {
                try await dataStore.saveUserConfig(userConfig)
                applyTheme()
            } catch {
                print("Failed to save user configuration: \(error)")
            }
        }
    }
    
    func resetToDefaults() {
        userConfig = UserConfig.default
        saveConfiguration()
    }
    
    // MARK: - Theme Management
    
    private func applyTheme() {
        // Apply theme to the app
        // This would typically involve updating the app's appearance
        // For now, we'll just ensure the configuration is saved
    }
    
    // MARK: - Data Management
    
    func clearAllConversations() async {
        do {
            try await dataStore.clearAllData()
            // Notify chat manager if available
            if let chatManager = chatManager {
                await chatManager.clearAllConversations()
            }
        } catch {
            print("Failed to clear all conversations: \(error)")
        }
    }
    
    func secureDataWipe() async {
        do {
            // Clear all conversations
            try await dataStore.clearAllData()
            
            // Clear encryption keys
            let encryptionManager = try EncryptionManager()
            try encryptionManager.deleteKeyFromKeychain()
            encryptionManager.clearSensitiveMemory()
            
            // Remove passcode
            try passcodeManager.removePasscode()
            passcodeManager.clearSensitiveMemory()
            
            // Reset configuration
            userConfig = UserConfig.default
            try await dataStore.saveUserConfig(userConfig)
            
            // Notify chat manager if available
            if let chatManager = chatManager {
                await chatManager.clearAllConversations()
            }
        } catch {
            print("Failed to perform secure data wipe: \(error)")
        }
    }
    
    // MARK: - Validation
    
    func validateConfiguration() -> [String] {
        var errors: [String] = []
        
        // Validate nickname
        if userConfig.nickname.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            errors.append("Nickname cannot be empty")
        }
        
        if userConfig.nickname.count > 50 {
            errors.append("Nickname must be 50 characters or less")
        }
        
        // AI parameters are validated in their initializer
        // but we can add additional business logic here if needed
        
        return errors
    }
    
    // MARK: - Configuration Presets
    
    func applyCreativePreset() {
        userConfig.aiParameters = AIParameters(
            temperature: 1.2,
            maxTokens: 2000,
            contextWindow: 15
        )
        saveConfiguration()
    }
    
    func applyBalancedPreset() {
        userConfig.aiParameters = AIParameters(
            temperature: 0.7,
            maxTokens: 1000,
            contextWindow: 10
        )
        saveConfiguration()
    }
    
    func applyFocusedPreset() {
        userConfig.aiParameters = AIParameters(
            temperature: 0.3,
            maxTokens: 800,
            contextWindow: 5
        )
        saveConfiguration()
    }
    
    // MARK: - Export/Import
    
    func exportConfiguration() -> Data? {
        do {
            return try JSONEncoder().encode(userConfig)
        } catch {
            print("Failed to export configuration: \(error)")
            return nil
        }
    }
    
    func importConfiguration(from data: Data) -> Bool {
        do {
            let importedConfig = try JSONDecoder().decode(UserConfig.self, from: data)
            userConfig = importedConfig
            saveConfiguration()
            return true
        } catch {
            print("Failed to import configuration: \(error)")
            return false
        }
    }
    
    // MARK: - Passcode Management
    
    func enablePasscode(_ passcode: String) throws {
        try passcodeManager.setPasscode(passcode)
        userConfig.passcodeEnabled = true
        saveConfiguration()
    }
    
    func disablePasscode() throws {
        try passcodeManager.removePasscode()
        userConfig.passcodeEnabled = false
        saveConfiguration()
    }
    
    func verifyPasscode(_ passcode: String) throws -> Bool {
        return try passcodeManager.verifyPasscode(passcode)
    }
    
    func lockApp() {
        passcodeManager.lockApp()
    }
    
    var isAppLocked: Bool {
        return passcodeManager.isLocked
    }
    
    var canUseBiometrics: Bool {
        return passcodeManager.canUseBiometrics()
    }
    
    func authenticateWithBiometrics() async throws -> Bool {
        return try await passcodeManager.authenticateWithBiometrics()
    }
    
    // MARK: - Onboarding
    
    func completeOnboarding() {
        userDefaults.set(true, forKey: "HasCompletedOnboarding")
        saveConfiguration()
    }
    
    func resetOnboarding() {
        userDefaults.removeObject(forKey: "HasCompletedOnboarding")
    }
}