import XCTest
@testable import SerenaNet

@MainActor
final class RTAIManagerTests: XCTestCase {
    var rtaiManager: RTAIManager!
    
    override func setUp() {
        super.setUp()
        rtaiManager = RTAIManager.shared
        rtaiManager.clearHistory() // Start with clean state
    }
    
    override func tearDown() {
        rtaiManager.clearHistory()
        rtaiManager = nil
        super.tearDown()
    }
    
    // MARK: - Task Detection Tests
    
    func testIsRTAITaskDetection() {
        // Valid RTAI tasks
        XCTAssertTrue(rtaiManager.isRTAITask("@taskid: generateSummary"))
        XCTAssertTrue(rtaiManager.isRTAITask("@task: analyze"))
        XCTAssertTrue(rtaiManager.isRTAITask("""
            @taskid: generateSummary
            input: test
            """))
        
        // Invalid RTAI tasks
        XCTAssertFalse(rtaiManager.isRTAITask("Regular message"))
        XCTAssertFalse(rtaiManager.isRTAITask("taskid: missing @"))
        XCTAssertFalse(rtaiManager.isRTAITask(""))
    }
    
    // MARK: - Task Parsing Tests
    
    func testTaskParsing() async throws {
        let taskInput = """
        @taskid: generateSummary
        input: This is test input
        tool: summarizer_v1
        route: default
        verify: signature
        """
        
        let result = try await rtaiManager.handle(taskInput)
        
        // Should not throw and should return a result
        XCTAssertFalse(result.isEmpty)
        XCTAssertTrue(result.contains("generateSummary") || result.contains("Summary"))
        
        // Check execution history
        let executions = rtaiManager.getRecentExecutions(limit: 1)
        XCTAssertEqual(executions.count, 1)
        
        let execution = executions.first!
        XCTAssertEqual(execution.task.taskId, "generateSummary")
        XCTAssertEqual(execution.task.input, "This is test input")
        XCTAssertEqual(execution.task.tool, "summarizer_v1")
        XCTAssertEqual(execution.task.route, "default")
        XCTAssertEqual(execution.task.verify, "signature")
    }
    
    func testTaskParsingWithMinimalFormat() async throws {
        let taskInput = "@taskid: analyze"
        
        let result = try await rtaiManager.handle(taskInput)
        
        XCTAssertFalse(result.isEmpty)
        
        let executions = rtaiManager.getRecentExecutions(limit: 1)
        XCTAssertEqual(executions.count, 1)
        
        let execution = executions.first!
        XCTAssertEqual(execution.task.taskId, "analyze")
        XCTAssertEqual(execution.task.input, "") // Default empty
        XCTAssertEqual(execution.task.tool, "default") // Default value
        XCTAssertEqual(execution.task.route, "default") // Default value
        XCTAssertEqual(execution.task.verify, "none") // Default value
    }
    
    func testInvalidTaskFormat() async {
        let invalidInput = """
        invalid format
        no taskid here
        """
        
        do {
            _ = try await rtaiManager.handle(invalidInput)
            XCTFail("Should have thrown an error for invalid format")
        } catch {
            XCTAssertTrue(error is SerenaError)
            if case SerenaError.invalidFTAIFormat = error {
                // Expected error
            } else {
                XCTFail("Expected invalidFTAIFormat error")
            }
        }
    }
    
    // MARK: - Task Execution Tests
    
    func testSummaryTaskExecution() async throws {
        let taskInput = """
        @taskid: generateSummary
        input: This is a long document that needs summarization
        tool: summarizer_v1
        """
        
        let result = try await rtaiManager.handle(taskInput)
        
        XCTAssertTrue(result.contains("Summary"))
        XCTAssertTrue(result.contains("summarizer_v1"))
    }
    
    func testAnalysisTaskExecution() async throws {
        let taskInput = """
        @taskid: analyze
        input: Data to analyze
        tool: analyzer_v2
        route: priority
        """
        
        let result = try await rtaiManager.handle(taskInput)
        
        XCTAssertTrue(result.contains("Analysis"))
        XCTAssertTrue(result.contains("analyzer_v2"))
        XCTAssertTrue(result.contains("priority"))
    }
    
    func testTranslationTaskExecution() async throws {
        let taskInput = """
        @taskid: translate
        input: Hello world
        tool: translator_v1
        """
        
        let result = try await rtaiManager.handle(taskInput)
        
        XCTAssertTrue(result.contains("Translation"))
        XCTAssertTrue(result.contains("translator_v1"))
    }
    
    func testGenericTaskExecution() async throws {
        let taskInput = """
        @taskid: customTask
        input: Custom input
        tool: custom_tool
        route: special
        verify: checksum
        """
        
        let result = try await rtaiManager.handle(taskInput)
        
        XCTAssertTrue(result.contains("customTask"))
        XCTAssertTrue(result.contains("custom_tool"))
        XCTAssertTrue(result.contains("special"))
        XCTAssertTrue(result.contains("checksum"))
    }
    
    // MARK: - History Management Tests
    
    func testExecutionHistory() async throws {
        // Execute multiple tasks
        let tasks = [
            "@taskid: task1\ninput: input1",
            "@taskid: task2\ninput: input2",
            "@taskid: task3\ninput: input3"
        ]
        
        for task in tasks {
            _ = try await rtaiManager.handle(task)
        }
        
        let history = rtaiManager.getRecentExecutions(limit: 10)
        XCTAssertEqual(history.count, 3)
        
        // Should be in reverse chronological order (most recent first)
        XCTAssertEqual(history[0].task.taskId, "task3")
        XCTAssertEqual(history[1].task.taskId, "task2")
        XCTAssertEqual(history[2].task.taskId, "task1")
    }
    
    func testHistoryLimit() async throws {
        // Execute more tasks than the limit
        for i in 1...15 {
            let task = "@taskid: task\(i)\ninput: input\(i)"
            _ = try await rtaiManager.handle(task)
        }
        
        let limitedHistory = rtaiManager.getRecentExecutions(limit: 5)
        XCTAssertEqual(limitedHistory.count, 5)
        
        // Should get the 5 most recent
        XCTAssertEqual(limitedHistory[0].task.input, "input15")
        XCTAssertEqual(limitedHistory[4].task.input, "input11")
    }
    
    func testClearHistory() async throws {
        // Execute a task
        _ = try await rtaiManager.handle("@taskid: test")
        
        XCTAssertEqual(rtaiManager.getRecentExecutions().count, 1)
        
        rtaiManager.clearHistory()
        
        XCTAssertEqual(rtaiManager.getRecentExecutions().count, 0)
    }
    
    // MARK: - Statistics Tests
    
    func testExecutionStats() async throws {
        // Execute some tasks
        _ = try await rtaiManager.handle("@taskid: generateSummary")
        _ = try await rtaiManager.handle("@taskid: generateSummary")
        _ = try await rtaiManager.handle("@taskid: analyze")
        
        let stats = rtaiManager.getExecutionStats()
        
        XCTAssertEqual(stats.totalExecutions, 3)
        XCTAssertEqual(stats.mostCommonTask, "generateSummary")
        XCTAssertEqual(stats.successRate, 1.0) // MVP assumes 100% success
        XCTAssertGreaterThan(stats.averageDuration, 0)
    }
    
    func testEmptyStats() {
        let stats = rtaiManager.getExecutionStats()
        
        XCTAssertEqual(stats.totalExecutions, 0)
        XCTAssertEqual(stats.mostCommonTask, "none")
        XCTAssertEqual(stats.successRate, 1.0)
        XCTAssertEqual(stats.averageDuration, 0)
    }
    
    // MARK: - Processing State Tests
    
    func testProcessingState() async throws {
        XCTAssertFalse(rtaiManager.isProcessing)
        
        let task = Task {
            _ = try await rtaiManager.handle("@taskid: test")
        }
        
        // Check processing state during execution
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(rtaiManager.isProcessing)
        
        try await task.value
        
        XCTAssertFalse(rtaiManager.isProcessing)
    }
}

// MARK: - Supporting Types Tests

final class RTAITaskTests: XCTestCase {
    
    func testRTAITaskDescription() {
        let task = RTAITask(
            taskId: "testTask",
            input: "test input",
            tool: "test_tool",
            route: "test_route",
            verify: "test_verify"
        )
        
        let description = task.description
        XCTAssertTrue(description.contains("testTask"))
        XCTAssertTrue(description.contains("test_tool"))
        XCTAssertTrue(description.contains("test_route"))
    }
}

final class RTAIExecutionTests: XCTestCase {
    
    func testRTAIExecutionFormatting() {
        let task = RTAITask(taskId: "test", input: "input", tool: "tool", route: "route", verify: "verify")
        let execution = RTAIExecution(
            id: "test-id",
            task: task,
            result: "test result",
            timestamp: Date(),
            duration: 1.234
        )
        
        XCTAssertEqual(execution.formattedDuration, "1.23s")
    }
}

final class RTAIStatsTests: XCTestCase {
    
    func testRTAIStatsFormatting() {
        let stats = RTAIStats(
            totalExecutions: 10,
            averageDuration: 1.567,
            mostCommonTask: "summary",
            successRate: 0.95
        )
        
        XCTAssertEqual(stats.formattedAverageDuration, "1.57s")
        XCTAssertEqual(stats.formattedSuccessRate, "95.0%")
    }
}