import Foundation
import SwiftUI

public struct UserConfig: Codable, Equatable {
    public var nickname: String
    public var theme: AppTheme
    public var voiceInputEnabled: Bool
    public var passcodeEnabled: Bool
    public var rtaiEnabled: Bool
    public var aiParameters: AIParameters
    public var voiceSettings: VoiceSettings
    
    public init(
        nickname: String = "User",
        theme: AppTheme = .system,
        voiceInputEnabled: Bool = true,
        passcodeEnabled: Bool = false,
        rtaiEnabled: Bool = true,
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
    
    public static let `default` = UserConfig()
}

public enum AppTheme: String, Codable, CaseIterable {
    case light
    case dark
    case system
    
    public var displayName: String {
        switch self {
        case .light:
            return "Light"
        case .dark:
            return "Dark"
        case .system:
            return "System"
        }
    }
    
    public var colorScheme: ColorScheme? {
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

public struct AIParameters: Codable, Equatable {
    public var temperature: Double
    public var maxTokens: Int
    public var contextWindow: Int
    
    public init(
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        contextWindow: Int = 10
    ) {
        self.temperature = max(0.0, min(2.0, temperature))
        self.maxTokens = max(100, min(4000, maxTokens))
        self.contextWindow = max(1, min(20, contextWindow))
    }
    
    public static let `default` = AIParameters()
}

public struct VoiceSettings: Codable, Equatable {
    public var noiseReductionEnabled: Bool
    public var voiceCommandsEnabled: Bool
    public var autoSendEnabled: Bool
    public var microphoneSensitivity: Float
    public var speechTimeout: TimeInterval
    public var language: String
    
    public init(
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
    
    public static let `default` = VoiceSettings()
}