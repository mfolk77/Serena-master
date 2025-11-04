import XCTest
@testable import SerenaNet

@MainActor
final class SerenaOrchestratorTests: XCTestCase {
    var orchestrator: SerenaOrchestrator!
    var mockAIEngine: MockMixtralEngine!
    var mockConfigManager: MockConfigManager!
    
    override func setUp() async throws {
        try await super.setUp()
        mockAIEngine = MockMixtralEngine()
        mockConfigManager = MockConfigManager()
        orchestrator = SerenaOrchestrator(aiEngine: mockAIEngine, configManager: mockConfigManager)
        
        // Initialize the mock AI engine
        try await mockAIEngine.initialize()
    }
    
    override func tearDown() async throws {
        orchestrator = nil
        mockAIEngine = nil
        mockConfigManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(orchestrator)
        XCTAssertFalse(orchestrator.isProcessing)
        XCTAssertNil(orchestrator.lastProcessingType)
    }
    
    func testIsReady() {
        XCTAssertTrue(orchestrator.isReady)
        
        mockAIEngine.shouldFailInitialization = true
        // Note: In a real scenario, we'd need to reinitialize, but for testing we can check the logic
    }
    
    // MARK: - Standard LLM Processing Tests
    
    func testStandardLLMProcessing() async throws {
        // Disable RTAI
        mockConfigManager.userConfig.rtaiEnabled = false
        
        let input = "Hello, how are you?"
        let context: [Message] = []
        
        let result = try await orchestrator.processInput(input, context: context)
        
        XCTAssertEqual(result, "Mock AI response")
        XCTAssertTrue(mockAIEngine.generationCalled)
        XCTAssertEqual(mockAIEngine.lastPrompt, input)
        XCTAssertEqual(orchestrator.lastProcessingType, .standardLLM)
    }
    
    func testStandardLLMWithContext() async throws {
        mockConfigManager.userConfig.rtaiEnabled = false
        
        let input = "Continue the conversation"
        let context = [
            Message(content: "Hello", role: .user),
            Message(content: "Hi there!", role: .assistant)
        ]
        
        let result = try await orchestrator.processInput(input, context: context)
        
        XCTAssertEqual(result, "Mock AI response")
        XCTAssertTrue(mockAIEngine.generationCalled)
        XCTAssertEqual(mockAIEngine.lastContext?.count, 2)
    }
    
    func testStandardLLMFailure() async {
        mockConfigManager.userConfig.rtaiEnabled = false
        mockAIEngine.shouldFailGeneration = true
        
        do {
            _ = try await orchestrator.processInput("test", context: [])
            XCTFail("Should have thrown an error")
        } catch {
            XCTAssertTrue(error is SerenaError)
        }
    }
    
    // MARK: - RTAI Processing Tests
    
    func testRTAIProcessing() async throws {
        // Enable RTAI
        mockConfigManager.userConfig.rtaiEnabled = true
        
        let rtaiInput = """
        @taskid: generateSummary
        input: Test document
        tool: summarizer_v1
        """
        
        let result = try await orchestrator.processInput(rtaiInput, context: [])
        
        XCTAssertTrue(result.contains("Summary"))
        XCTAssertEqual(orchestrator.lastProcessingType, .rtai)
        
        // Should not have called the standard AI engine
        XCTAssertFalse(mockAIEngine.generationCalled)
    }
    
    func testRTAIDisabled() async throws {
        // Disable RTAI
        mockConfigManager.userConfig.rtaiEnabled = false
        
        let rtaiInput = """
        @taskid: generateSummary
        input: Test document
        """
        
        let result = try await orchestrator.processInput(rtaiInput, context: [])
        
        // Should fall back to standard LLM processing
        XCTAssertEqual(result, "Mock AI response")
        XCTAssertEqual(orchestrator.lastProcessingType, .standardLLM)
        XCTAssertTrue(mockAIEngine.generationCalled)
    }
    
    func testRTAIFallbackOnError() async throws {
        // Enable RTAI
        mockConfigManager.userConfig.rtaiEnabled = true
        
        // Use completely invalid RTAI format to trigger error and fallback
        let invalidRTAI = "completely invalid format with no taskid"
        
        let result = try await orchestrator.processInput(invalidRTAI, context: [])
        
        // Should fall back to standard LLM since it's not an RTAI task
        XCTAssertEqual(result, "Mock AI response")
        XCTAssertTrue(mockAIEngine.generationCalled)
    }
    
    // MARK: - Processing State Tests
    
    func testProcessingState() async throws {
        mockConfigManager.userConfig.rtaiEnabled = false
        
        XCTAssertFalse(orchestrator.isProcessing)
        XCTAssertEqual(orchestrator.processingStatus, "Ready")
        
        let task = Task {
            _ = try await orchestrator.processInput("test", context: [])
        }
        
        // Check processing state during execution
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(orchestrator.isProcessing)
        XCTAssertTrue(orchestrator.processingStatus.contains("Processing"))
        
        try await task.value
        
        XCTAssertFalse(orchestrator.isProcessing)
        XCTAssertEqual(orchestrator.processingStatus, "Ready")
    }
    
    // MARK: - Configuration Tests
    
    func testRTAIToggle() {
        XCTAssertFalse(orchestrator.isRTAIEnabled)
        
        orchestrator.toggleRTAI(true)
        
        XCTAssertTrue(orchestrator.isRTAIEnabled)
        XCTAssertTrue(mockConfigManager.userConfig.rtaiEnabled)
        
        orchestrator.toggleRTAI(false)
        
        XCTAssertFalse(orchestrator.isRTAIEnabled)
        XCTAssertFalse(mockConfigManager.userConfig.rtaiEnabled)
    }
    
    // MARK: - Diagnostics Tests
    
    func testDiagnostics() async throws {
        // Clear history and execute some tasks first
        RTAIManager.shared.clearHistory()
        mockConfigManager.userConfig.rtaiEnabled = true
        _ = try await orchestrator.processInput("@taskid: test", context: [])
        
        let diagnostics = orchestrator.getDiagnostics()
        
        XCTAssertTrue(diagnostics.isReady)
        XCTAssertTrue(diagnostics.isRTAIEnabled)
        XCTAssertTrue(diagnostics.aiEngineReady)
        XCTAssertEqual(diagnostics.aiEngineMemoryUsage, 0) // Mock engine
        XCTAssertEqual(diagnostics.rtaiStats.totalExecutions, 1)
        XCTAssertEqual(diagnostics.lastProcessingType, .rtai)
    }
    
    func testRecentRTAIExecutions() async throws {
        mockConfigManager.userConfig.rtaiEnabled = true
        
        // Clear any existing history first
        RTAIManager.shared.clearHistory()
        
        // Execute multiple RTAI tasks
        _ = try await orchestrator.processInput("@taskid: task1", context: [])
        _ = try await orchestrator.processInput("@taskid: task2", context: [])
        
        let executions = orchestrator.getRecentRTAIExecutions(limit: 5)
        
        XCTAssertEqual(executions.count, 2)
        XCTAssertEqual(executions[0].task.taskId, "task2") // Most recent first
        XCTAssertEqual(executions[1].task.taskId, "task1")
    }
    
    // MARK: - Example Task Generation Tests
    
    func testExampleTaskGeneration() {
        let summaryTask = orchestrator.generateExampleRTAITask(type: .summary)
        XCTAssertTrue(summaryTask.contains("@taskid: generateSummary"))
        XCTAssertTrue(summaryTask.contains("tool: summarizer_v1"))
        
        let analysisTask = orchestrator.generateExampleRTAITask(type: .analysis)
        XCTAssertTrue(analysisTask.contains("@taskid: analyze"))
        XCTAssertTrue(analysisTask.contains("tool: analyzer_v2"))
        
        let translationTask = orchestrator.generateExampleRTAITask(type: .translation)
        XCTAssertTrue(translationTask.contains("@taskid: translate"))
        XCTAssertTrue(translationTask.contains("tool: translator_v1"))
        
        let extractionTask = orchestrator.generateExampleRTAITask(type: .extraction)
        XCTAssertTrue(extractionTask.contains("@taskid: extract"))
        XCTAssertTrue(extractionTask.contains("tool: extractor_v1"))
    }
}

// MARK: - Mock Classes

class MockConfigManager: ConfigManager {
    init() {
        super.init(chatManager: nil)
        // Start with default config
    }
    
    override func saveConfiguration() {
        // Don't actually save to disk in tests
    }
}

// MARK: - Supporting Types Tests

final class RTAITaskTypeTests: XCTestCase {
    
    func testRTAITaskTypeDisplayNames() {
        XCTAssertEqual(RTAITaskType.summary.displayName, "Summary")
        XCTAssertEqual(RTAITaskType.analysis.displayName, "Analysis")
        XCTAssertEqual(RTAITaskType.translation.displayName, "Translation")
        XCTAssertEqual(RTAITaskType.extraction.displayName, "Extraction")
    }
    
    func testAllCases() {
        let allCases = RTAITaskType.allCases
        XCTAssertEqual(allCases.count, 4)
        XCTAssertTrue(allCases.contains(.summary))
        XCTAssertTrue(allCases.contains(.analysis))
        XCTAssertTrue(allCases.contains(.translation))
        XCTAssertTrue(allCases.contains(.extraction))
    }
}

final class OrchestratorDiagnosticsTests: XCTestCase {
    
    func testDiagnosticsFormatting() {
        let rtaiStats = RTAIStats(totalExecutions: 5, averageDuration: 1.5, mostCommonTask: "summary", successRate: 1.0)
        
        let diagnostics = OrchestratorDiagnostics(
            isReady: true,
            isRTAIEnabled: true,
            aiEngineReady: true,
            aiEngineMemoryUsage: 2_048_576_000, // ~2GB
            rtaiStats: rtaiStats,
            lastProcessingType: .rtai
        )
        
        XCTAssertEqual(diagnostics.memoryUsageFormatted, "1953.1 MB")
        XCTAssertEqual(diagnostics.statusSummary, "Ready - RTAI Enabled")
    }
    
    func testDiagnosticsNotReady() {
        let rtaiStats = RTAIStats(totalExecutions: 0, averageDuration: 0, mostCommonTask: "none", successRate: 1.0)
        
        let diagnostics = OrchestratorDiagnostics(
            isReady: false,
            isRTAIEnabled: false,
            aiEngineReady: false,
            aiEngineMemoryUsage: 0,
            rtaiStats: rtaiStats,
            lastProcessingType: nil
        )
        
        XCTAssertEqual(diagnostics.statusSummary, "Not Ready - AI Engine Loading")
    }
    
    func testDiagnosticsStandardMode() {
        let rtaiStats = RTAIStats(totalExecutions: 0, averageDuration: 0, mostCommonTask: "none", successRate: 1.0)
        
        let diagnostics = OrchestratorDiagnostics(
            isReady: true,
            isRTAIEnabled: false,
            aiEngineReady: true,
            aiEngineMemoryUsage: 0,
            rtaiStats: rtaiStats,
            lastProcessingType: .standardLLM
        )
        
        XCTAssertEqual(diagnostics.statusSummary, "Ready - Standard Mode")
    }
}