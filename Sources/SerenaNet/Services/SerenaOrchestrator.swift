import Foundation
import os.log

/// Central orchestrator that routes between RTAI tasks and standard LLM queries
@MainActor
class SerenaOrchestrator: ObservableObject {
    @Published private(set) var isProcessing = false
    @Published private(set) var lastProcessingType: ProcessingType?
    
    private let aiEngine: any AIEngine
    private let rtaiManager: RTAIManager
    private let configManager: ConfigManager
    private let logger = Logger(subsystem: "com.serenanet.orchestrator", category: "SerenaOrchestrator")
    
    enum ProcessingType {
        case rtai
        case standardLLM
    }
    
    init(aiEngine: any AIEngine, configManager: ConfigManager) {
        self.aiEngine = aiEngine
        self.rtaiManager = RTAIManager.shared
        self.configManager = configManager
    }
    
    // MARK: - Main Processing Entry Point
    
    /// Process user input through appropriate AI system
    func processInput(_ input: String, context: [Message] = []) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Processing input (length: \(input.count))")
        
        // Check if RTAI is enabled and if this is an RTAI task
        if configManager.userConfig.rtaiEnabled && rtaiManager.isRTAITask(input) {
            return try await handleRTAITask(input)
        } else {
            return try await handleStandardLLMQuery(input, context: context)
        }
    }
    
    // MARK: - RTAI Task Handling
    
    private func handleRTAITask(_ input: String) async throws -> String {
        lastProcessingType = .rtai
        logger.info("Routing to RTAI system")
        
        do {
            let result = try await rtaiManager.handle(input)
            logger.info("RTAI task completed successfully")
            return result
        } catch {
            logger.error("RTAI task failed: \(error.localizedDescription)")
            
            // Fallback to standard LLM if RTAI fails
            logger.info("Falling back to standard LLM processing")
            return try await handleStandardLLMQuery(input, context: [])
        }
    }
    
    // MARK: - Standard LLM Query Handling
    
    private func handleStandardLLMQuery(_ input: String, context: [Message]) async throws -> String {
        lastProcessingType = .standardLLM
        logger.info("Routing to standard LLM system")
        
        guard aiEngine.isReady else {
            throw SerenaError.aiModelNotLoaded
        }
        
        do {
            let result = try await aiEngine.generateResponse(for: input, context: context)
            logger.info("Standard LLM query completed successfully")
            return result
        } catch {
            logger.error("Standard LLM query failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Orchestrator Status
    
    /// Check if the orchestrator is ready to process requests
    var isReady: Bool {
        return aiEngine.isReady
    }
    
    /// Get current processing status
    var processingStatus: String {
        if isProcessing {
            switch lastProcessingType {
            case .rtai:
                return "Processing RTAI task..."
            case .standardLLM:
                return "Processing with AI model..."
            case .none:
                return "Processing..."
            }
        } else {
            return "Ready"
        }
    }
    
    /// Check if RTAI is currently enabled
    var isRTAIEnabled: Bool {
        return configManager.userConfig.rtaiEnabled
    }
    
    // MARK: - Configuration Management
    
    /// Toggle RTAI functionality
    func toggleRTAI(_ enabled: Bool) {
        configManager.userConfig.rtaiEnabled = enabled
        configManager.saveConfiguration()
        
        logger.info("RTAI \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Diagnostics and Monitoring
    
    /// Get orchestrator diagnostics
    func getDiagnostics() -> OrchestratorDiagnostics {
        let rtaiStats = rtaiManager.getExecutionStats()
        
        return OrchestratorDiagnostics(
            isReady: isReady,
            isRTAIEnabled: isRTAIEnabled,
            aiEngineReady: aiEngine.isReady,
            aiEngineMemoryUsage: aiEngine.memoryUsage,
            rtaiStats: rtaiStats,
            lastProcessingType: lastProcessingType
        )
    }
    
    /// Get recent RTAI executions for monitoring
    func getRecentRTAIExecutions(limit: Int = 5) -> [RTAIExecution] {
        return rtaiManager.getRecentExecutions(limit: limit)
    }
    
    // MARK: - Example RTAI Task Generation
    
    /// Generate example RTAI task for testing/demonstration
    func generateExampleRTAITask(type: RTAITaskType = .summary) -> String {
        switch type {
        case .summary:
            return """
            @taskid: generateSummary
            input: This is a long document that needs to be summarized for quick understanding.
            tool: summarizer_v1
            route: default
            verify: signature
            """
            
        case .analysis:
            return """
            @taskid: analyze
            input: User feedback data from the last quarter showing mixed satisfaction scores.
            tool: analyzer_v2
            route: priority
            verify: checksum
            """
            
        case .translation:
            return """
            @taskid: translate
            input: Hello, how are you doing today?
            tool: translator_v1
            route: default
            verify: none
            """
            
        case .extraction:
            return """
            @taskid: extract
            input: Extract key metrics from the quarterly report document.
            tool: extractor_v1
            route: default
            verify: signature
            """
        }
    }
}

// MARK: - Supporting Types

enum RTAITaskType: CaseIterable {
    case summary
    case analysis
    case translation
    case extraction
    
    var displayName: String {
        switch self {
        case .summary:
            return "Summary"
        case .analysis:
            return "Analysis"
        case .translation:
            return "Translation"
        case .extraction:
            return "Extraction"
        }
    }
}

struct OrchestratorDiagnostics {
    let isReady: Bool
    let isRTAIEnabled: Bool
    let aiEngineReady: Bool
    let aiEngineMemoryUsage: Int64
    let rtaiStats: RTAIStats
    let lastProcessingType: SerenaOrchestrator.ProcessingType?
    
    var memoryUsageFormatted: String {
        let mb = Double(aiEngineMemoryUsage) / (1024 * 1024)
        return String(format: "%.1f MB", mb)
    }
    
    var statusSummary: String {
        if !isReady {
            return "Not Ready - AI Engine Loading"
        } else if isRTAIEnabled {
            return "Ready - RTAI Enabled"
        } else {
            return "Ready - Standard Mode"
        }
    }
}