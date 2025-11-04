import Foundation

/// Protocol defining the interface for AI engines in SerenaNet
@MainActor
protocol AIEngine: ObservableObject {
    /// Current initialization state of the AI engine
    var isReady: Bool { get }
    
    /// Current memory usage in bytes
    var memoryUsage: Int64 { get }
    
    /// Maximum context length supported by the engine
    var maxContextLength: Int { get }
    
    /// Current model loading progress (0.0 to 1.0)
    var loadingProgress: Double { get }
    
    /// Initialize the AI engine and load the model
    /// - Throws: SerenaError if initialization fails
    func initialize() async throws
    
    /// Generate a response for the given prompt with conversation context
    /// - Parameters:
    ///   - prompt: The user's input message
    ///   - context: Previous messages for context (limited by maxContextLength)
    /// - Returns: Generated response text
    /// - Throws: SerenaError if generation fails
    func generateResponse(for prompt: String, context: [Message]) async throws -> String
    
    /// Generate a streaming response for better user experience
    /// - Parameters:
    ///   - prompt: The user's input message
    ///   - context: Previous messages for context
    /// - Returns: AsyncStream of partial response chunks
    /// - Throws: SerenaError if generation fails
    func generateStreamingResponse(for prompt: String, context: [Message]) async throws -> AsyncStream<String>
    
    /// Cleanup resources and prepare for shutdown
    func cleanup() async
    
    /// Check if the engine can handle the current memory pressure
    /// - Returns: true if the engine can continue operating
    func canHandleMemoryPressure() -> Bool
    
    /// Reduce memory usage by clearing caches or reducing model precision
    func handleMemoryPressure() async throws
}

/// Configuration parameters for AI engines
struct AIEngineConfiguration {
    let temperature: Double
    let maxTokens: Int
    let topP: Double
    let frequencyPenalty: Double
    let presencePenalty: Double
    
    static let `default` = AIEngineConfiguration(
        temperature: 0.7,
        maxTokens: 1000,
        topP: 0.9,
        frequencyPenalty: 0.0,
        presencePenalty: 0.0
    )
}

/// Memory usage statistics for monitoring
struct AIEngineMemoryStats {
    let totalMemoryUsage: Int64
    let modelMemoryUsage: Int64
    let cacheMemoryUsage: Int64
    let availableMemory: Int64
    let memoryPressureLevel: MemoryPressureLevel
}

enum MemoryPressureLevel {
    case normal
    case moderate
    case high
    case critical
    
    var description: String {
        switch self {
        case .normal:
            return "Normal"
        case .moderate:
            return "Moderate"
        case .high:
            return "High"
        case .critical:
            return "Critical"
        }
    }
}