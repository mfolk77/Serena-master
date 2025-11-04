import Foundation
#if canImport(CryptoKit)
import CryptoKit
#endif

public enum ModelType: String, Codable {
    case mistral, mixtral, llama
    var displayName: String { rawValue.capitalized }
}

public enum ModelError: Error {
    case modelNotLoaded
}

public protocol Skill { func call(_ input: String) async throws -> String }

public struct SHA256 {
    public static func hash(data: Data) -> [UInt8] {
        #if canImport(CryptoKit)
        return Array(CryptoKit.SHA256.hash(data: data))
        #else
        return Array(repeating: 0, count: 32) // fallback stub
        #endif
    }
}

public actor OllamaService {
    public static let shared = OllamaService()
    public var isRunning: Bool = true
    public var useMockMode: Bool = false
    public var availableModels: [String] = ["llama", "mistral", "mixtral"]
    public var currentModel: String? = nil
    public func checkOllamaStatus() async -> Bool { true }
    public func loadAvailableModels() async {}
    public func generate(prompt: String) async throws -> String { "Ollama mock reply for \(prompt)" }
    public func generateResponse(prompt: String) async -> String { "Ollama response for \(prompt)" }
} 