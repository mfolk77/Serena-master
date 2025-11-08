import Foundation
import SwiftUI

/// Protocol defining the interface for AI engines
@MainActor
public protocol AIEngine: ObservableObject {
    /// Whether the AI engine is ready to process requests
    var isReady: Bool { get }
    
    /// Initialize the AI engine
    func initialize() async throws
    
    /// Process input and generate a response
    func processInput(_ input: String, context: [Message]) async throws -> String
    
    /// Generate response (legacy method name for compatibility)
    func generateResponse(for input: String, context: [Message]) async throws -> String
    
    /// Memory usage in bytes
    var memoryUsage: Int64 { get }
    
    /// Update the engine configuration
    func updateConfiguration(_ configuration: AIEngineConfiguration) async
    
    /// Get current memory statistics
    func getMemoryStats() async -> AIEngineMemoryStats
    
    /// Check if the engine can handle memory pressure
    func canHandleMemoryPressure() async -> Bool
    
    /// Handle memory pressure by cleaning up resources
    func handleMemoryPressure() async throws
}

/// Configuration for AI engines
public struct AIEngineConfiguration: Codable, Equatable {
    public let temperature: Double
    public let maxTokens: Int
    public let contextWindow: Int
    public let modelPath: String?
    
    public init(
        temperature: Double = 0.7,
        maxTokens: Int = 1000,
        contextWindow: Int = 10,
        modelPath: String? = nil
    ) {
        self.temperature = temperature
        self.maxTokens = maxTokens
        self.contextWindow = contextWindow
        self.modelPath = modelPath
    }
    
    public static let `default` = AIEngineConfiguration()
}

/// Memory statistics for AI engines
public struct AIEngineMemoryStats: Codable, Equatable {
    public let totalMemoryUsage: Int64
    public let modelMemoryUsage: Int64
    public let cacheMemoryUsage: Int64
    public let availableMemory: Int64
    public let memoryPressureLevel: MemoryPressureLevel
    
    public init(
        totalMemoryUsage: Int64,
        modelMemoryUsage: Int64,
        cacheMemoryUsage: Int64,
        availableMemory: Int64,
        memoryPressureLevel: MemoryPressureLevel
    ) {
        self.totalMemoryUsage = totalMemoryUsage
        self.modelMemoryUsage = modelMemoryUsage
        self.cacheMemoryUsage = cacheMemoryUsage
        self.availableMemory = availableMemory
        self.memoryPressureLevel = memoryPressureLevel
    }
}

/// Memory pressure levels
public enum MemoryPressureLevel: String, Codable, CaseIterable {
    case normal
    case warning
    case critical
    
    public var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .warning:
            return "Warning"
        case .critical:
            return "Critical"
        }
    }
}