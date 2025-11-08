import XCTest
@testable import SerenaNet

@MainActor
final class EndToEndIntegrationTests: XCTestCase {
    var chatManager: ChatManager!
    var mockDataStore: MockDataStore!
    var mockAIEngine: MockAIEngine!
    var mockVoiceManager: MockVoiceManager!
    var mockNetworkManager: MockNetworkConnectivityManager!
    var configManager: ConfigManager!
    var errorManager: ErrorManager!
    
    override func setUp() async throws {
        try await super.setUp()
        
        // Set up mock dependencies
        mockDataStore = MockDataStore()
        mockAIEngine = MockAIEngine()
        mockVoiceManager = MockVoiceManager()
        mockNetworkManager = MockNetworkConnectivityManager()
        configManager = ConfigManager()
        errorManager = ErrorManager()
        
        // Create ChatManager with mocked dependencies
        chatManager = ChatManager(
            dataStore: mockDataStore,
            errorManager: errorManager,
            voiceManager: mockVoiceManager,
            networkManager: mockNetworkManager,
            aiEngine: mockAIEngine,
            configManager: configManager
        )
        
        // Initialize AI engine
        try await mockAIEngine.initialize()
    }
    
    override func tearDown() async throws {
        chatManager = nil
        mockDataStore = nil
        mockAIEngine = nil
        mockVoiceManager = nil
        mockNetworkManager = nil
        configManager = nil
        errorManager = nil
        try await super.tearDown()
    }
    
    // MARK: - Complete Conversation Flow Tests
    
    func testCompleteConversationFlow() async throws {
        // Test the complete flow: create conversation -> send message -> AI response -> save
        
        // 1. Load conversations (should be empty initially)
        await chatManager.loadConversations()
        XCTAssertEqual(chatManager.conversations.count, 0)
        
        // 2. Create new conversation
        chatManager.createNewConversation()
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.conversations.count, 1)
        
        // 3. Send a message
        let userMessage = "Hello, how are you?"
        await chatManager.sendMessage(userMessage)
        
        // 4. Verify user message was added
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        XCTAssertEqual(conversation.messages.count, 2) // User message + AI response
        XCTAssertEqual(conversation.messages[0].content, userMessage)
        XCTAssertEqual(conversation.messages[0].role, .user)
        
        // 5. Verify AI response was generated
        XCTAssertEqual(conversation.messages[1].role, .assistant)
        XCTAssertFalse(conversation.messages[1].content.isEmpty)
        
        // 6. Verify conversation was saved
        XCTAssertTrue(mockDataStore.saveConversationCalled)
        XCTAssertEqual(mockDataStore.savedConversations.count, 1)
        
        // 7. Verify processing state is reset
        XCTAssertFalse(chatManager.isProcessing)
    }
    
    func testMultipleMessageConversation() async throws {
        // Test a conversation with multiple exchanges
        
        chatManager.createNewConversation()
        
        let messages = [
            "What is Swift?",
            "Can you explain closures?",
            "How do I use async/await?"
        ]
        
        for (index, message) in messages.enumerated() {
            await chatManager.sendMessage(message)
            
            guard let conversation = chatManager.currentConversation else {
                XCTFail("Current conversation should not be nil")
                return
            }
            
            // Each message should result in user message + AI response
            let expectedMessageCount = (index + 1) * 2
            XCTAssertEqual(conversation.messages.count, expectedMessageCount)
            
            // Verify the latest user message
            let userMessageIndex = expectedMessageCount - 2
            XCTAssertEqual(conversation.messages[userMessageIndex].content, message)
            XCTAssertEqual(conversation.messages[userMessageIndex].role, .user)
            
            // Verify AI response exists
            let aiMessageIndex = expectedMessageCount - 1
            XCTAssertEqual(conversation.messages[aiMessageIndex].role, .assistant)
            XCTAssertFalse(conversation.messages[aiMessageIndex].content.isEmpty)
        }
        
        // Verify all conversations were saved
        XCTAssertEqual(mockDataStore.savedConversations.count, 1)
        XCTAssertEqual(mockDataStore.savedConversations[0].messages.count, 6) // 3 exchanges = 6 messages
    }
    
    func testConversationPersistenceFlow() async throws {
        // Test that conversations persist across app sessions
        
        // 1. Create and populate a conversation
        chatManager.createNewConversation()
        await chatManager.sendMessage("Test message 1")
        await chatManager.sendMessage("Test message 2")
        
        let originalConversationId = chatManager.currentConversation?.id
        let originalMessageCount = chatManager.currentConversation?.messages.count
        
        // 2. Simulate app restart by creating new ChatManager
        let newChatManager = ChatManager(
            dataStore: mockDataStore,
            errorManager: errorManager,
            voiceManager: mockVoiceManager,
            networkManager: mockNetworkManager,
            aiEngine: mockAIEngine,
            configManager: configManager
        )
        
        // 3. Load conversations
        await newChatManager.loadConversations()
        
        // 4. Verify conversation was restored
        XCTAssertEqual(newChatManager.conversations.count, 1)
        XCTAssertEqual(newChatManager.currentConversation?.id, originalConversationId)
        XCTAssertEqual(newChatManager.currentConversation?.messages.count, originalMessageCount)
    }
    
    // MARK: - Voice Input Integration Tests
    
    func testVoiceInputFlow() async throws {
        // Test complete voice input flow
        
        chatManager.createNewConversation()
        
        // 1. Set up voice manager to return transcription
        mockVoiceManager.mockTranscription = "This is a voice message"
        mockVoiceManager.mockPermissionStatus = .authorized
        
        // 2. Start voice input
        do {
            _ = try await chatManager.startVoiceInput()
        } catch {
            // Expected to throw since we're not actually recording
        }
        
        // 3. Simulate stopping voice input with transcription
        let transcription = await chatManager.stopVoiceInput()
        
        // 4. Verify transcription was processed
        XCTAssertEqual(transcription, "This is a voice message")
        
        // 5. Verify message was sent and AI responded
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        XCTAssertEqual(conversation.messages.count, 2)
        XCTAssertEqual(conversation.messages[0].content, "This is a voice message")
        XCTAssertEqual(conversation.messages[0].role, .user)
        XCTAssertEqual(conversation.messages[1].role, .assistant)
    }
    
    func testVoiceInputPermissionFlow() async throws {
        // Test voice input when permissions are not granted
        
        mockVoiceManager.mockPermissionStatus = .denied
        
        do {
            _ = try await chatManager.startVoiceInput()
            XCTFail("Should have thrown permission error")
        } catch SerenaError.voicePermissionDenied {
            // Expected error
            XCTAssertEqual(chatManager.lastError, .voicePermissionDenied)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Offline Mode Integration Tests
    
    func testOfflineModeFlow() async throws {
        // Test that the app works completely offline
        
        // 1. Set network to offline
        mockNetworkManager.mockIsConnected = false
        
        // 2. Create conversation and send message
        chatManager.createNewConversation()
        await chatManager.sendMessage("Test offline message")
        
        // 3. Verify everything still works
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        XCTAssertEqual(conversation.messages.count, 2)
        XCTAssertEqual(conversation.messages[0].content, "Test offline message")
        XCTAssertEqual(conversation.messages[1].role, .assistant)
        
        // 4. Verify data was saved locally
        XCTAssertTrue(mockDataStore.saveConversationCalled)
        
        // 5. Verify offline status is reported correctly
        XCTAssertTrue(chatManager.isOffline)
        XCTAssertFalse(chatManager.networkStatusMessage.isEmpty)
    }
    
    func testNetworkStatusTransitions() async throws {
        // Test transitions between online and offline states
        
        // 1. Start online
        mockNetworkManager.mockIsConnected = true
        XCTAssertFalse(chatManager.isOffline)
        
        // 2. Go offline
        mockNetworkManager.mockIsConnected = false
        XCTAssertTrue(chatManager.isOffline)
        
        // 3. Send message while offline (should still work)
        chatManager.createNewConversation()
        await chatManager.sendMessage("Offline message")
        
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        XCTAssertEqual(conversation.messages.count, 2)
        
        // 4. Go back online
        mockNetworkManager.mockIsConnected = true
        XCTAssertFalse(chatManager.isOffline)
        
        // 5. Send another message (should still work)
        await chatManager.sendMessage("Online message")
        XCTAssertEqual(conversation.messages.count, 4)
    }
    
    // MARK: - Error Handling Integration Tests
    
    func testAIEngineFailureRecovery() async throws {
        // Test recovery when AI engine fails
        
        chatManager.createNewConversation()
        
        // 1. Make AI engine fail
        mockAIEngine.shouldFail = true
        mockAIEngine.failureError = SerenaError.aiModelNotLoaded
        
        // 2. Send message
        await chatManager.sendMessage("Test message")
        
        // 3. Verify error was handled
        XCTAssertEqual(chatManager.lastError, .aiModelNotLoaded)
        
        // 4. Verify user message was still saved
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        XCTAssertEqual(conversation.messages.count, 1) // Only user message, no AI response
        XCTAssertEqual(conversation.messages[0].content, "Test message")
        XCTAssertEqual(conversation.messages[0].role, .user)
        
        // 5. Fix AI engine and try again
        mockAIEngine.shouldFail = false
        await chatManager.sendMessage("Second message")
        
        // 6. Verify recovery
        XCTAssertNil(chatManager.lastError)
        XCTAssertEqual(conversation.messages.count, 4) // Both messages + AI response for second
    }
    
    func testDataStoreFailureRecovery() async throws {
        // Test recovery when data store fails
        
        chatManager.createNewConversation()
        
        // 1. Make data store fail
        mockDataStore.shouldFailSave = true
        mockDataStore.saveError = SerenaError.databaseError("Test database error")
        
        // 2. Send message
        await chatManager.sendMessage("Test message")
        
        // 3. Verify error was handled but conversation continues in memory
        XCTAssertEqual(chatManager.lastError, .databaseError("Test database error"))
        
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        // Messages should still be in memory
        XCTAssertEqual(conversation.messages.count, 2)
        
        // 4. Fix data store
        mockDataStore.shouldFailSave = false
        await chatManager.sendMessage("Second message")
        
        // 5. Verify recovery
        XCTAssertNil(chatManager.lastError)
        XCTAssertTrue(mockDataStore.saveConversationCalled)
    }
    
    // MARK: - Context Management Integration Tests
    
    func testContextWindowManagement() async throws {
        // Test that context window is properly managed in long conversations
        
        chatManager.createNewConversation()
        
        // Send more messages than the context window allows (10 exchanges = 20 messages)
        for i in 1...25 {
            await chatManager.sendMessage("Message \(i)")
        }
        
        guard let conversation = chatManager.currentConversation else {
            XCTFail("Current conversation should not be nil")
            return
        }
        
        // Should have 50 messages total (25 user + 25 AI)
        XCTAssertEqual(conversation.messages.count, 50)
        
        // Get context messages for AI processing
        let contextMessages = chatManager.getContextMessages(for: conversation)
        
        // Context should be limited to 20 messages (10 exchanges)
        XCTAssertLessThanOrEqual(contextMessages.count, 20)
        
        // Should include the most recent messages
        let lastMessage = conversation.messages.last!
        XCTAssertTrue(contextMessages.contains { $0.id == lastMessage.id })
        
        // Get context statistics
        let stats = chatManager.getContextStatistics(for: conversation)
        XCTAssertEqual(stats.totalMessages, 50)
        XCTAssertLessThanOrEqual(stats.contextMessages, 20)
        XCTAssertTrue(stats.isContextTrimmed)
    }
    
    // MARK: - Performance Integration Tests
    
    func testPerformanceMonitoringIntegration() async throws {
        // Test that performance monitoring works with real operations
        
        let performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.startMonitoring()
        performanceMonitor.clearPerformanceData()
        
        // Perform operations that should be monitored
        chatManager.createNewConversation()
        await chatManager.sendMessage("Performance test message")
        
        // Wait a moment for monitoring to update
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        let report = performanceMonitor.getPerformanceReport()
        
        // Verify performance metrics were recorded
        XCTAssertGreaterThan(report.currentMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(report.totalResponseMeasurements, 1)
        XCTAssertGreaterThan(report.lastResponseTime, 0)
        
        performanceMonitor.stopMonitoring()
    }
    
    // MARK: - Configuration Integration Tests
    
    func testConfigurationIntegration() async throws {
        // Test that configuration changes affect behavior
        
        // 1. Change AI parameters
        configManager.userConfig.aiParameters.temperature = 0.5
        configManager.userConfig.aiParameters.maxTokens = 500
        
        // 2. Create conversation and send message
        chatManager.createNewConversation()
        await chatManager.sendMessage("Test with custom config")
        
        // 3. Verify AI engine received the configuration
        XCTAssertTrue(mockAIEngine.generateResponseCalled)
        
        // 4. Change voice settings
        configManager.userConfig.voiceInputEnabled = false
        
        // 5. Try voice input (should be disabled)
        // Note: This would need to be implemented in the actual voice manager
        // For now, we just verify the setting is stored
        XCTAssertFalse(configManager.userConfig.voiceInputEnabled)
    }
    
    // MARK: - Multi-Conversation Integration Tests
    
    func testMultipleConversationsManagement() async throws {
        // Test managing multiple conversations
        
        // 1. Create first conversation
        chatManager.createNewConversation()
        let firstConversationId = chatManager.currentConversation?.id
        await chatManager.sendMessage("First conversation message")
        
        // 2. Create second conversation
        chatManager.createNewConversation()
        let secondConversationId = chatManager.currentConversation?.id
        await chatManager.sendMessage("Second conversation message")
        
        // 3. Verify we have two conversations
        XCTAssertEqual(chatManager.conversations.count, 2)
        XCTAssertNotEqual(firstConversationId, secondConversationId)
        
        // 4. Switch back to first conversation
        guard let firstConversation = chatManager.conversations.first(where: { $0.id == firstConversationId }) else {
            XCTFail("First conversation not found")
            return
        }
        
        chatManager.selectConversation(firstConversation)
        XCTAssertEqual(chatManager.currentConversation?.id, firstConversationId)
        
        // 5. Send message to first conversation
        await chatManager.sendMessage("Another message to first conversation")
        
        // 6. Verify message was added to correct conversation
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 4) // 2 exchanges
        
        // 7. Verify second conversation is unchanged
        guard let secondConversation = chatManager.conversations.first(where: { $0.id == secondConversationId }) else {
            XCTFail("Second conversation not found")
            return
        }
        
        XCTAssertEqual(secondConversation.messages.count, 2) // 1 exchange
    }
    
    func testConversationDeletionFlow() async throws {
        // Test deleting conversations
        
        // 1. Create multiple conversations
        chatManager.createNewConversation()
        let firstId = chatManager.currentConversation?.id
        await chatManager.sendMessage("First message")
        
        chatManager.createNewConversation()
        let secondId = chatManager.currentConversation?.id
        await chatManager.sendMessage("Second message")
        
        XCTAssertEqual(chatManager.conversations.count, 2)
        
        // 2. Delete first conversation
        guard let firstConversation = chatManager.conversations.first(where: { $0.id == firstId }) else {
            XCTFail("First conversation not found")
            return
        }
        
        await chatManager.deleteConversation(firstConversation)
        
        // 3. Verify deletion
        XCTAssertEqual(chatManager.conversations.count, 1)
        XCTAssertEqual(chatManager.currentConversation?.id, secondId)
        XCTAssertTrue(mockDataStore.deleteConversationCalled)
        
        // 4. Delete last conversation
        guard let secondConversation = chatManager.conversations.first(where: { $0.id == secondId }) else {
            XCTFail("Second conversation not found")
            return
        }
        
        await chatManager.deleteConversation(secondConversation)
        
        // 5. Verify new conversation was created
        XCTAssertEqual(chatManager.conversations.count, 1)
        XCTAssertNotEqual(chatManager.currentConversation?.id, secondId)
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 0)
    }
}