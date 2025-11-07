import XCTest
@testable import SerenaNet

@MainActor
final class RTAIIntegrationTests: XCTestCase {
    var chatManager: ChatManager!
    var mockDataStore: RTAIMockDataStore!
    var mockConfigManager: RTAIMockConfigManager!
    var mockAIEngine: RTAIMockMixtralEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDataStore = RTAIMockDataStore()
        mockConfigManager = RTAIMockConfigManager()
        mockAIEngine = RTAIMockMixtralEngine()
        
        // Initialize the mock AI engine
        try await mockAIEngine.initialize()
        
        chatManager = ChatManager(
            dataStore: mockDataStore,
            errorManager: ErrorManager(),
            aiEngine: mockAIEngine,
            configManager: mockConfigManager
        )
    }
    
    override func tearDown() async throws {
        chatManager = nil
        mockDataStore = nil
        mockConfigManager = nil
        mockAIEngine = nil
        try await super.tearDown()
    }
    
    // MARK: - End-to-End RTAI Tests
    
    func testRTAIEnabledEndToEnd() async throws {
        // Enable RTAI
        mockConfigManager.userConfig.rtaiEnabled = true
        
        // Send an RTAI task through the chat system
        let rtaiMessage = """
        @taskid: generateSummary
        input: This is a test document that needs to be summarized
        tool: summarizer_v1
        route: default
        verify: signature
        """
        
        await chatManager.sendMessage(rtaiMessage)
        
        // Verify the conversation was created and contains both user and AI messages
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.currentMessageCount, 2) // User + AI response
        
        // Verify the AI response is from RTAI (contains "Summary")
        let lastMessage = chatManager.lastMessage
        XCTAssertEqual(lastMessage?.role, .assistant)
        XCTAssertTrue(lastMessage?.content.contains("Summary") ?? false)
        
        // Verify the standard AI engine was NOT called
        XCTAssertFalse(mockAIEngine.generationCalled)
        
        // Verify RTAI execution was logged
        let rtaiExecutions = RTAIManager.shared.getRecentExecutions(limit: 1)
        XCTAssertEqual(rtaiExecutions.count, 1)
        XCTAssertEqual(rtaiExecutions.first?.task.taskId, "generateSummary")
    }
    
    func testRTAIDisabledFallsBackToStandardLLM() async throws {
        // Clear RTAI history to ensure clean state
        RTAIManager.shared.clearHistory()
        
        // Disable RTAI
        mockConfigManager.userConfig.rtaiEnabled = false
        
        // Send an RTAI-formatted message
        let rtaiMessage = """
        @taskid: generateSummary
        input: This should go to standard LLM
        """
        
        await chatManager.sendMessage(rtaiMessage)
        
        // Verify the conversation was created
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.currentMessageCount, 2)
        
        // Verify the response is from standard LLM
        let lastMessage = chatManager.lastMessage
        XCTAssertEqual(lastMessage?.role, .assistant)
        XCTAssertEqual(lastMessage?.content, "Mock AI response")
        
        // Verify the standard AI engine WAS called
        XCTAssertTrue(mockAIEngine.generationCalled)
        
        // Verify no RTAI execution was logged
        let rtaiExecutions = RTAIManager.shared.getRecentExecutions(limit: 1)
        XCTAssertEqual(rtaiExecutions.count, 0)
    }
    
    func testMixedConversationWithRTAIAndStandard() async throws {
        // Enable RTAI
        mockConfigManager.userConfig.rtaiEnabled = true
        
        // Send a standard message first
        await chatManager.sendMessage("Hello, how are you?")
        
        // Verify standard LLM was used
        XCTAssertTrue(mockAIEngine.generationCalled)
        XCTAssertEqual(chatManager.currentMessageCount, 2)
        
        // Reset the mock
        mockAIEngine.generationCalled = false
        
        // Send an RTAI task
        let rtaiMessage = """
        @taskid: analyze
        input: Analyze this conversation
        tool: analyzer_v1
        """
        
        await chatManager.sendMessage(rtaiMessage)
        
        // Verify we now have 4 messages total
        XCTAssertEqual(chatManager.currentMessageCount, 4)
        
        // Verify the last message is from RTAI
        let lastMessage = chatManager.lastMessage
        XCTAssertTrue(lastMessage?.content.contains("Analysis") ?? false)
        
        // Verify standard LLM was NOT called for the RTAI task
        XCTAssertFalse(mockAIEngine.generationCalled)
        
        // Verify RTAI execution was logged
        let rtaiExecutions = RTAIManager.shared.getRecentExecutions(limit: 1)
        XCTAssertEqual(rtaiExecutions.count, 1)
        XCTAssertEqual(rtaiExecutions.first?.task.taskId, "analyze")
    }
    
    func testRTAITaskTypes() async throws {
        mockConfigManager.userConfig.rtaiEnabled = true
        RTAIManager.shared.clearHistory()
        
        let taskTypes = [
            ("generateSummary", "Summary"),
            ("analyze", "Analysis"),
            ("translate", "Translation"),
            ("extract", "Extracted")
        ]
        
        for (taskId, expectedContent) in taskTypes {
            let rtaiMessage = """
            @taskid: \(taskId)
            input: Test input for \(taskId)
            tool: test_tool
            """
            
            await chatManager.sendMessage(rtaiMessage)
            
            let lastMessage = chatManager.lastMessage
            XCTAssertTrue(lastMessage?.content.contains(expectedContent) ?? false, 
                         "Expected '\(expectedContent)' in response for task '\(taskId)'")
        }
        
        // Verify all tasks were logged
        let executions = RTAIManager.shared.getRecentExecutions(limit: 10)
        XCTAssertEqual(executions.count, 4)
    }
    
    // MARK: - Configuration Integration Tests
    
    func testRTAIToggleIntegration() async throws {
        // Start with RTAI disabled
        mockConfigManager.userConfig.rtaiEnabled = false
        
        let rtaiMessage = "@taskid: test"
        
        // First attempt - should use standard LLM
        await chatManager.sendMessage(rtaiMessage)
        XCTAssertTrue(mockAIEngine.generationCalled)
        
        // Reset mock
        mockAIEngine.generationCalled = false
        
        // Enable RTAI
        mockConfigManager.userConfig.rtaiEnabled = true
        
        // Second attempt - should use RTAI
        await chatManager.sendMessage(rtaiMessage)
        XCTAssertFalse(mockAIEngine.generationCalled) // RTAI was used instead
        
        let executions = RTAIManager.shared.getRecentExecutions(limit: 1)
        XCTAssertEqual(executions.count, 1)
    }
}

// MARK: - Mock Classes for Integration Tests

class RTAIMockConfigManager: ConfigManager {
    init() {
        super.init(chatManager: nil)
        // Start with default config
    }
    
    override func saveConfiguration() {
        // Don't actually save to disk in tests
    }
}

class RTAIMockDataStore: DataStoreProtocol {
    var conversations: [Conversation] = []
    var savedConversations: [Conversation] = []
    var deletedConversationIds: [UUID] = []
    var clearedAllData = false
    
    var shouldFailLoad = false
    var shouldFailSave = false
    var shouldFailDelete = false
    var shouldFailClear = false
    
    func loadConversations() async throws -> [Conversation] {
        if shouldFailLoad {
            throw SerenaError.databaseError("Mock load failure")
        }
        return conversations
    }
    
    func saveConversation(_ conversation: Conversation) async throws {
        if shouldFailSave {
            throw SerenaError.databaseError("Mock save failure")
        }
        savedConversations.append(conversation)
    }
    
    func deleteConversation(id: UUID) async throws {
        if shouldFailDelete {
            throw SerenaError.databaseError("Mock delete failure")
        }
        deletedConversationIds.append(id)
    }
    
    func clearAllData() async throws {
        if shouldFailClear {
            throw SerenaError.databaseError("Mock clear failure")
        }
        clearedAllData = true
    }
}

@MainActor
class RTAIMockMixtralEngine: AIEngine {
    var shouldFailInitialization = false
    var shouldFailGeneration = false
    var mockResponse = "Mock AI response"
    var initializationCalled = false
    var generationCalled = false
    var lastPrompt: String?
    var lastContext: [Message]?
    
    @Published private(set) var isReady: Bool = false
    @Published private(set) var memoryUsage: Int64 = 0
    @Published private(set) var loadingProgress: Double = 0.0
    
    let maxContextLength: Int = 10
    
    func initialize() async throws {
        initializationCalled = true
        if shouldFailInitialization {
            throw SerenaError.aiModelInitializationFailed("Mock initialization failure")
        }
        isReady = true
    }
    
    func generateResponse(for prompt: String, context: [Message]) async throws -> String {
        generationCalled = true
        lastPrompt = prompt
        lastContext = context
        
        if shouldFailGeneration {
            throw SerenaError.aiResponseGenerationFailed("Mock generation failure")
        }
        
        // Add a small delay to simulate AI processing
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        return mockResponse
    }
    
    func generateStreamingResponse(for prompt: String, context: [Message]) async throws -> AsyncStream<String> {
        let response = try await generateResponse(for: prompt, context: context)
        return AsyncStream { continuation in
            continuation.yield(response)
            continuation.finish()
        }
    }
    
    func cleanup() async {
        isReady = false
        memoryUsage = 0
    }
    
    func canHandleMemoryPressure() -> Bool {
        return true
    }
    
    func handleMemoryPressure() async throws {
        // Mock implementation - do nothing
    }
}