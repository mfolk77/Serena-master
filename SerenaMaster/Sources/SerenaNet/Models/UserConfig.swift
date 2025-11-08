import Foundation
import SwiftUI

struct UserConfig: Codable, Equatable {
    var nickname: String
    var theme: AppTheme
    var voiceInputEnabled: Bool
    var passcodeEnabled: Bool
    var rtaiEnabled: Bool
    var aiParameters: AIParameters
    var voiceSettings: VoiceSettings
    
    init(
        nickname: String = "User",
        theme: AppTheme = .system,
        voiceInputEnabled: Bool = true,
        passcodeEnabled: Bool = false,
        rtaiEnabled: Bool = false,
        aiParameters: AIParameters = AIParameters(),
        voiceSettings: VoiceSettings = VoiceSettings()
    ) {
        self.nickname = nickname
        self.theme = theme
        self.voiceInputEnabled = voiceInputEnabled
        self.passcodeEnabled = passcodeEnabled
        self.rtaiEnabled = rtaiEnabled
        self.aiParameters = aiParameters
        self.voiceSettings = voiceSettings
    }
    
    static let `default` = UserConfig()
}

enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case system
    
    var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    var colorScheme: ColorScheme? {
        switch self {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

struct AIParameters: Codable, Equatable {
    var temperature: Double
    var maxTokens: Int
    var contextWindow: Int
    
    init(
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        contextWindow: Int = 10
    ) {
        self.temperature = max(0.0, min(2.0, temperature))
        self.maxTokens = max(100, min(4000, maxTokens))
        self.contextWindow = max(1, min(20, contextWindow))
    }
    
    static let `default` = AIParameters()
}

struct VoiceSettings: Codable, Equatable {
    var noiseReductionEnabled: Bool
    var voiceCommandsEnabled: Bool
    var autoSendEnabled: Bool
    var microphoneSensitivity: Float
    var speechTimeout: TimeInterval
    var language: String
    
    init(
        noiseReductionEnabled: Bool = true,
        voiceCommandsEnabled: Bool = true,
        autoSendEnabled: Bool = false,
        microphoneSensitivity: Float = 0.5,
        speechTimeout: TimeInterval = 3.0,
        language: String = "en-US"
    ) {
        self.noiseReductionEnabled = noiseReductionEnabled
        self.voiceCommandsEnabled = voiceCommandsEnabled
        self.autoSendEnabled = autoSendEnabled
        self.microphoneSensitivity = max(0.0, min(1.0, microphoneSensitivity))
        self.speechTimeout = max(1.0, min(10.0, speechTimeout))
        self.language = language
    }
    
    static let `default` = VoiceSettings()
}