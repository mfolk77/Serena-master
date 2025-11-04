import Foundation
import os.log

/// Real-Time AI (RTAI) Manager for handling structured task execution
@MainActor
class RTAIManager: ObservableObject {
    static let shared = RTAIManager()
    
    @Published private(set) var isProcessing = false
    @Published private(set) var executionHistory: [RTAIExecution] = []
    
    private let logger = Logger(subsystem: "com.serenanet.rtai", category: "RTAIManager")
    private let maxHistorySize = 100
    
    private init() {}
    
    // MARK: - RTAI Task Handling
    
    /// Check if input contains an RTAI task
    func isRTAITask(_ input: String) -> Bool {
        return input.contains("@taskid:") || input.contains("@task:")
    }
    
    /// Handle RTAI task execution
    func handle(_ input: String) async throws -> String {
        logger.info("Handling RTAI task")
        
        guard let task = parseRTAITask(input) else {
            throw SerenaError.invalidFTAIFormat("Invalid RTAI task format")
        }
        
        // Register the task
        let executionId = register(task)
        
        // Enqueue for execution
        enqueue(executionId: executionId, task: task)
        
        // Execute the task
        let result = try await execute(executionId: executionId, task: task)
        
        // Log the execution
        logExecution(executionId: executionId, task: task, result: result)
        
        return result
    }
    
    // MARK: - Core RTAI Operations
    
    /// Register a new RTAI task and return execution ID
    func register(_ task: RTAITask) -> String {
        let executionId = UUID().uuidString.prefix(8).description
        logger.info("Registered RTAI task: \(executionId) - \(task.taskId)")
        return executionId
    }
    
    /// Enqueue task for execution
    func enqueue(executionId: String, task: RTAITask) {
        logger.info("Enqueued RTAI task: \(executionId)")
        // For MVP, we execute immediately. Later this could be a proper queue
    }
    
    /// Execute the RTAI task
    func execute(executionId: String, task: RTAITask) async throws -> String {
        isProcessing = true
        defer { isProcessing = false }
        
        logger.info("Executing RTAI task: \(executionId) - \(task.taskId)")
        
        // Simulate execution time
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        // For MVP, simulate execution based on task type
        let result = simulateExecution(task)
        
        logger.info("RTAI task completed: \(executionId)")
        return result
    }
    
    /// Log task execution
    func logExecution(executionId: String, task: RTAITask, result: String) {
        let execution = RTAIExecution(
            id: executionId,
            task: task,
            result: result,
            timestamp: Date(),
            duration: 0.5 // Simulated duration
        )
        
        executionHistory.insert(execution, at: 0)
        
        // Limit history size
        if executionHistory.count > maxHistorySize {
            executionHistory = Array(executionHistory.prefix(maxHistorySize))
        }
        
        logger.info("Logged RTAI execution: \(executionId)")
    }
    
    // MARK: - Task Parsing
    
    private func parseRTAITask(_ input: String) -> RTAITask? {
        // Parse RTAI task format:
        // @taskid: generateSummary
        // input: userMessage
        // tool: summarizer_v1
        // route: default
        // verify: signature
        
        let lines = input.components(separatedBy: .newlines)
        var taskId: String?
        var inputData: String?
        var tool: String?
        var route: String?
        var verify: String?
        
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            if trimmed.hasPrefix("@taskid:") || trimmed.hasPrefix("@task:") {
                taskId = String(trimmed.dropFirst(8)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("input:") {
                inputData = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("tool:") {
                tool = String(trimmed.dropFirst(5)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("route:") {
                route = String(trimmed.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            } else if trimmed.hasPrefix("verify:") {
                verify = String(trimmed.dropFirst(7)).trimmingCharacters(in: .whitespaces)
            }
        }
        
        guard let taskId = taskId else {
            logger.error("Failed to parse RTAI task: missing taskid")
            return nil
        }
        
        return RTAITask(
            taskId: taskId,
            input: inputData ?? "",
            tool: tool ?? "default",
            route: route ?? "default",
            verify: verify ?? "none"
        )
    }
    
    // MARK: - Simulation (MVP)
    
    private func simulateExecution(_ task: RTAITask) -> String {
        logger.info("Simulating RTAI task execution: \(task.taskId)")
        
        switch task.taskId.lowercased() {
        case "generatesummary", "summarize":
            return "📋 Summary: \(task.input.prefix(50))... [Generated using \(task.tool)]"
            
        case "analyze", "analysis":
            return "🔍 Analysis: Key insights from '\(task.input.prefix(30))...' [Tool: \(task.tool), Route: \(task.route)]"
            
        case "translate":
            return "🌐 Translation: [Simulated translation of '\(task.input.prefix(30))...'] [Tool: \(task.tool)]"
            
        case "extract", "extraction":
            return "📤 Extracted: [Key data from '\(task.input.prefix(30))...'] [Tool: \(task.tool)]"
            
        case "generate", "creation":
            return "✨ Generated: [New content based on '\(task.input.prefix(30))...'] [Tool: \(task.tool)]"
            
        default:
            return "⚙️ RTAI Task '\(task.taskId)' executed successfully with input: '\(task.input.prefix(50))...' [Tool: \(task.tool), Route: \(task.route), Verify: \(task.verify)]"
        }
    }
    
    // MARK: - History and Monitoring
    
    /// Get recent executions
    func getRecentExecutions(limit: Int = 10) -> [RTAIExecution] {
        return Array(executionHistory.prefix(limit))
    }
    
    /// Clear execution history
    func clearHistory() {
        executionHistory.removeAll()
        logger.info("Cleared RTAI execution history")
    }
    
    /// Get execution statistics
    func getExecutionStats() -> RTAIStats {
        let totalExecutions = executionHistory.count
        let averageDuration = executionHistory.isEmpty ? 0 : executionHistory.map(\.duration).reduce(0, +) / Double(totalExecutions)
        
        let taskTypes = Dictionary(grouping: executionHistory, by: { $0.task.taskId })
        let mostCommonTask = taskTypes.max(by: { $0.value.count < $1.value.count })?.key ?? "none"
        
        return RTAIStats(
            totalExecutions: totalExecutions,
            averageDuration: averageDuration,
            mostCommonTask: mostCommonTask,
            successRate: 1.0 // For MVP, assume 100% success
        )
    }
}

// MARK: - Supporting Types

struct RTAITask {
    let taskId: String
    let input: String
    let tool: String
    let route: String
    let verify: String
    
    var description: String {
        return "Task: \(taskId), Tool: \(tool), Route: \(route)"
    }
}

struct RTAIExecution: Identifiable {
    let id: String
    let task: RTAITask
    let result: String
    let timestamp: Date
    let duration: Double
    
    var formattedDuration: String {
        return String(format: "%.2fs", duration)
    }
}

struct RTAIStats {
    let totalExecutions: Int
    let averageDuration: Double
    let mostCommonTask: String
    let successRate: Double
    
    var formattedAverageDuration: String {
        return String(format: "%.2fs", averageDuration)
    }
    
    var formattedSuccessRate: String {
        return String(format: "%.1f%%", successRate * 100)
    }
}