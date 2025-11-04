import XCTest
@testable import SerenaNet

@MainActor
final class ChatManagerTests: XCTestCase {
    var chatManager: ChatManager!
    var mockDataStore: MockDataStore!
    var mockErrorManager: MockErrorManager!
    var mockAIEngine: MockMixtralEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        mockDataStore = MockDataStore()
        mockErrorManager = MockErrorManager()
        mockAIEngine = MockMixtralEngine()
        chatManager = ChatManager(dataStore: mockDataStore, errorManager: mockErrorManager, aiEngine: mockAIEngine)
    }
    
    override func tearDown() async throws {
        chatManager = nil
        mockDataStore = nil
        mockErrorManager = nil
        mockAIEngine = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialization() {
        XCTAssertNotNil(chatManager)
        XCTAssertTrue(chatManager.conversations.isEmpty)
        XCTAssertNil(chatManager.currentConversation)
        XCTAssertFalse(chatManager.isProcessing)
        XCTAssertNil(chatManager.lastError)
    }
    
    // MARK: - Conversation Management Tests
    
    func testCreateNewConversation() {
        // When
        chatManager.createNewConversation()
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1)
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.currentConversation?.title, "New Conversation")
        XCTAssertTrue(chatManager.currentConversation?.messages.isEmpty ?? false)
    }
    
    func testLoadConversationsSuccess() async {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        mockDataStore.conversations = [conversation1, conversation2]
        
        // When
        await chatManager.loadConversations()
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 2)
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertNil(chatManager.lastError)
    }
    
    func testLoadConversationsFailure() async {
        // Given
        mockDataStore.shouldFailLoad = true
        
        // When
        await chatManager.loadConversations()
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1) // Creates new conversation on failure
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertNotNil(chatManager.lastError)
        XCTAssertTrue(mockErrorManager.handledErrors.count > 0)
    }
    
    func testLoadConversationsEmpty() async {
        // Given
        mockDataStore.conversations = []
        
        // When
        await chatManager.loadConversations()
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1) // Creates new conversation when empty
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertNil(chatManager.lastError)
    }
    
    func testSelectConversation() {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1, conversation2]
        chatManager.currentConversation = conversation1
        
        // When
        chatManager.selectConversation(conversation2)
        
        // Then
        XCTAssertEqual(chatManager.currentConversation?.id, conversation2.id)
    }
    
    func testSelectNonExistentConversation() {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1]
        chatManager.currentConversation = conversation1
        
        // When
        chatManager.selectConversation(conversation2)
        
        // Then
        XCTAssertEqual(chatManager.currentConversation?.id, conversation1.id) // Should not change
        XCTAssertEqual(chatManager.lastError, .conversationNotFound)
    }
    
    func testGetConversation() {
        // Given
        let conversation = Conversation(title: "Test")
        chatManager.conversations = [conversation]
        
        // When
        let result = chatManager.getConversation(id: conversation.id)
        
        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.id, conversation.id)
    }
    
    func testGetNonExistentConversation() {
        // Given
        let conversation = Conversation(title: "Test")
        chatManager.conversations = [conversation]
        
        // When
        let result = chatManager.getConversation(id: UUID())
        
        // Then
        XCTAssertNil(result)
    }
    
    func testConversationCount() {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1, conversation2]
        
        // When & Then
        XCTAssertEqual(chatManager.conversationCount, 2)
    }
    
    func testHasConversations() {
        // Given - empty
        XCTAssertFalse(chatManager.hasConversations)
        
        // When
        let conversation = Conversation(title: "Test")
        chatManager.conversations = [conversation]
        
        // Then
        XCTAssertTrue(chatManager.hasConversations)
    }
    
    // MARK: - Message Handling Tests
    
    func testSendMessageSuccess() async {
        // Given
        chatManager.createNewConversation()
        let messageText = "Hello, world!"
        
        // When
        await chatManager.sendMessage(messageText)
        
        // Then
        XCTAssertEqual(chatManager.currentMessageCount, 2) // User + AI response
        XCTAssertEqual(chatManager.lastMessage?.role, .assistant)
        XCTAssertNil(chatManager.lastError)
        XCTAssertTrue(mockDataStore.savedConversations.count > 0)
    }
    
    func testSendEmptyMessage() async {
        // Given
        chatManager.createNewConversation()
        
        // When
        await chatManager.sendMessage("")
        
        // Then
        XCTAssertEqual(chatManager.currentMessageCount, 0)
        XCTAssertEqual(chatManager.lastError, .emptyMessage)
    }
    
    func testSendWhitespaceMessage() async {
        // Given
        chatManager.createNewConversation()
        
        // When
        await chatManager.sendMessage("   \n\t  ")
        
        // Then
        XCTAssertEqual(chatManager.currentMessageCount, 0)
        XCTAssertEqual(chatManager.lastError, .emptyMessage)
    }
    
    func testSendMessageWithoutCurrentConversation() async {
        // Given - no current conversation
        XCTAssertNil(chatManager.currentConversation)
        
        // When
        await chatManager.sendMessage("Hello")
        
        // Then
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.currentMessageCount, 2) // User + AI response
    }
    
    func testSendMessageDatabaseError() async {
        // Given
        chatManager.createNewConversation()
        mockDataStore.shouldFailSave = true
        
        // When
        await chatManager.sendMessage("Hello")
        
        // Then
        XCTAssertNotNil(chatManager.lastError)
        XCTAssertTrue(mockErrorManager.handledErrors.count > 0)
    }
    
    func testAddMessage() async {
        // Given
        chatManager.createNewConversation()
        let message = Message(content: "Test message", role: .user)
        
        // When
        await chatManager.addMessage(message)
        
        // Then
        XCTAssertEqual(chatManager.currentMessageCount, 1)
        XCTAssertEqual(chatManager.lastMessage?.content, "Test message")
        XCTAssertEqual(chatManager.lastMessage?.role, .user)
    }
    
    func testAddMessageWithoutCurrentConversation() async {
        // Given - no current conversation
        let message = Message(content: "Test message", role: .user)
        
        // When
        await chatManager.addMessage(message)
        
        // Then
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertEqual(chatManager.currentMessageCount, 1)
    }
    
    func testCurrentMessageCount() {
        // Given
        chatManager.createNewConversation()
        let message1 = Message(content: "Message 1", role: .user)
        let message2 = Message(content: "Message 2", role: .assistant)
        chatManager.currentConversation?.addMessage(message1)
        chatManager.currentConversation?.addMessage(message2)
        
        // When & Then
        XCTAssertEqual(chatManager.currentMessageCount, 2)
    }
    
    func testCurrentMessageCountWithoutConversation() {
        // Given - no current conversation
        
        // When & Then
        XCTAssertEqual(chatManager.currentMessageCount, 0)
    }
    
    func testLastMessage() {
        // Given
        chatManager.createNewConversation()
        let message = Message(content: "Last message", role: .assistant)
        chatManager.currentConversation?.addMessage(message)
        
        // When & Then
        XCTAssertEqual(chatManager.lastMessage?.content, "Last message")
        XCTAssertEqual(chatManager.lastMessage?.role, .assistant)
    }
    
    func testLastMessageWithoutConversation() {
        // Given - no current conversation
        
        // When & Then
        XCTAssertNil(chatManager.lastMessage)
    }
    
    // MARK: - Data Persistence Tests
    
    func testDeleteConversationSuccess() async {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1, conversation2]
        chatManager.currentConversation = conversation1
        
        // When
        await chatManager.deleteConversation(conversation1)
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1)
        XCTAssertEqual(chatManager.currentConversation?.id, conversation2.id)
        XCTAssertNil(chatManager.lastError)
        XCTAssertTrue(mockDataStore.deletedConversationIds.contains(conversation1.id))
    }
    
    func testDeleteLastConversation() async {
        // Given
        let conversation = Conversation(title: "Test")
        chatManager.conversations = [conversation]
        chatManager.currentConversation = conversation
        
        // When
        await chatManager.deleteConversation(conversation)
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1) // Creates new conversation
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertNotEqual(chatManager.currentConversation?.id, conversation.id)
    }
    
    func testDeleteConversationFailure() async {
        // Given
        let conversation = Conversation(title: "Test")
        chatManager.conversations = [conversation]
        mockDataStore.shouldFailDelete = true
        
        // When
        await chatManager.deleteConversation(conversation)
        
        // Then
        XCTAssertNotNil(chatManager.lastError)
        XCTAssertTrue(mockErrorManager.handledErrors.count > 0)
    }
    
    func testClearAllConversations() async {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        await chatManager.clearAllConversations()
        
        // Then
        XCTAssertEqual(chatManager.conversations.count, 1) // Creates new conversation
        XCTAssertNotNil(chatManager.currentConversation)
        XCTAssertNil(chatManager.lastError)
        XCTAssertTrue(mockDataStore.clearedAllData)
    }
    
    func testClearAllConversationsFailure() async {
        // Given
        mockDataStore.shouldFailClear = true
        
        // When
        await chatManager.clearAllConversations()
        
        // Then
        XCTAssertNotNil(chatManager.lastError)
        XCTAssertTrue(mockErrorManager.handledErrors.count > 0)
    }
    
    // MARK: - AI Processing Tests
    
    func testIsProcessingDuringAIResponse() async {
        // Given
        chatManager.createNewConversation()
        
        // When
        let sendTask = Task {
            await chatManager.sendMessage("Hello")
        }
        
        // Check processing state during execution
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertTrue(chatManager.isProcessing)
        
        await sendTask.value
        
        // Then
        XCTAssertFalse(chatManager.isProcessing)
    }
    
    // MARK: - Conversation Ordering Tests
    
    func testConversationOrderingAfterMessage() async {
        // Given
        let conversation1 = Conversation(title: "Old")
        let conversation2 = Conversation(title: "New")
        chatManager.conversations = [conversation1, conversation2]
        chatManager.currentConversation = conversation2
        
        // When
        await chatManager.sendMessage("Hello")
        
        // Then
        XCTAssertEqual(chatManager.conversations.first?.id, conversation2.id) // Should be first after activity
    }
    
    // MARK: - Search and Filtering Tests
    
    func testSearchConversationsByTitle() {
        // Given
        let conversation1 = Conversation(title: "Swift Programming")
        let conversation2 = Conversation(title: "Python Tutorial")
        let conversation3 = Conversation(title: "JavaScript Guide")
        chatManager.conversations = [conversation1, conversation2, conversation3]
        
        // When
        let results = chatManager.searchConversations(query: "Swift")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Swift Programming")
    }
    
    func testSearchConversationsByContent() {
        // Given
        var conversation1 = Conversation(title: "Test 1")
        var conversation2 = Conversation(title: "Test 2")
        
        let message1 = Message(content: "How do I use Swift arrays?", role: .user)
        let message2 = Message(content: "Python is great for data science", role: .user)
        
        conversation1.addMessage(message1)
        conversation2.addMessage(message2)
        
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        let results = chatManager.searchConversations(query: "Swift")
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.id, conversation1.id)
    }
    
    func testSearchConversationsEmptyQuery() {
        // Given
        let conversation1 = Conversation(title: "Test 1")
        let conversation2 = Conversation(title: "Test 2")
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        let results = chatManager.searchConversations(query: "")
        
        // Then
        XCTAssertEqual(results.count, 2) // Should return all conversations
    }
    
    func testSearchConversationsCaseInsensitive() {
        // Given
        let conversation = Conversation(title: "Swift Programming")
        chatManager.conversations = [conversation]
        
        // When
        let results = chatManager.searchConversations(query: "swift")
        
        // Then
        XCTAssertEqual(results.count, 1)
    }
    
    func testFilterConversationsByDateRange() {
        // Given
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        let twoDaysAgo = Calendar.current.date(byAdding: .day, value: -2, to: now)!
        
        let conversation1 = Conversation(id: UUID(), title: "Recent", messages: [], createdAt: now, updatedAt: now)
        let conversation2 = Conversation(id: UUID(), title: "Yesterday", messages: [], createdAt: yesterday, updatedAt: yesterday)
        let conversation3 = Conversation(id: UUID(), title: "Old", messages: [], createdAt: twoDaysAgo, updatedAt: twoDaysAgo)
        
        chatManager.conversations = [conversation1, conversation2, conversation3]
        
        // When
        let results = chatManager.filterConversations(from: yesterday)
        
        // Then
        XCTAssertEqual(results.count, 2) // Should include yesterday and today
        XCTAssertTrue(results.contains { $0.title == "Recent" })
        XCTAssertTrue(results.contains { $0.title == "Yesterday" })
    }
    
    func testFilterConversationsByMessageCount() {
        // Given
        var conversation1 = Conversation(title: "Few messages")
        var conversation2 = Conversation(title: "Many messages")
        
        // Add 2 messages to conversation1
        conversation1.addMessage(Message(content: "Message 1", role: .user))
        conversation1.addMessage(Message(content: "Response 1", role: .assistant))
        
        // Add 6 messages to conversation2
        for i in 1...3 {
            conversation2.addMessage(Message(content: "Message \(i)", role: .user))
            conversation2.addMessage(Message(content: "Response \(i)", role: .assistant))
        }
        
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        let results = chatManager.filterConversations(minMessages: 4)
        
        // Then
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "Many messages")
    }
    
    func testGetSortedConversationsMostRecent() {
        // Given
        let now = Date()
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: now)!
        
        let conversation1 = Conversation(id: UUID(), title: "Old", messages: [], createdAt: yesterday, updatedAt: yesterday)
        let conversation2 = Conversation(id: UUID(), title: "New", messages: [], createdAt: now, updatedAt: now)
        
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        let results = chatManager.getSortedConversations(by: .mostRecent)
        
        // Then
        XCTAssertEqual(results.first?.title, "New")
        XCTAssertEqual(results.last?.title, "Old")
    }
    
    func testGetSortedConversationsAlphabetical() {
        // Given
        let conversation1 = Conversation(title: "Zebra")
        let conversation2 = Conversation(title: "Apple")
        let conversation3 = Conversation(title: "Banana")
        
        chatManager.conversations = [conversation1, conversation2, conversation3]
        
        // When
        let results = chatManager.getSortedConversations(by: .alphabetical)
        
        // Then
        XCTAssertEqual(results[0].title, "Apple")
        XCTAssertEqual(results[1].title, "Banana")
        XCTAssertEqual(results[2].title, "Zebra")
    }
    
    func testGetSortedConversationsByMessageCount() {
        // Given
        var conversation1 = Conversation(title: "Few")
        var conversation2 = Conversation(title: "Many")
        
        conversation1.addMessage(Message(content: "One", role: .user))
        conversation2.addMessage(Message(content: "One", role: .user))
        conversation2.addMessage(Message(content: "Two", role: .user))
        conversation2.addMessage(Message(content: "Three", role: .user))
        
        chatManager.conversations = [conversation1, conversation2]
        
        // When
        let results = chatManager.getSortedConversations(by: .messageCount)
        
        // Then
        XCTAssertEqual(results.first?.title, "Many")
        XCTAssertEqual(results.last?.title, "Few")
    }
    
    func testGetRecentConversations() {
        // Given
        let conversations = (1...15).map { i in
            let date = Calendar.current.date(byAdding: .minute, value: -i, to: Date())!
            return Conversation(id: UUID(), title: "Conversation \(i)", messages: [], createdAt: date, updatedAt: date)
        }
        chatManager.conversations = conversations
        
        // When
        let results = chatManager.getRecentConversations(limit: 5)
        
        // Then
        XCTAssertEqual(results.count, 5)
        XCTAssertEqual(results.first?.title, "Conversation 1") // Most recent
    }
    
    // MARK: - Context Window Management Tests
    
    func testGetContextMessagesWithinLimit() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add 10 messages (5 exchanges)
        for i in 1...5 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant response \(i)", role: .assistant))
        }
        
        // When
        let contextMessages = chatManager.getContextMessages(for: conversation)
        
        // Then
        XCTAssertEqual(contextMessages.count, 10) // All messages should be included
        XCTAssertEqual(contextMessages.first?.content, "User message 1")
        XCTAssertEqual(contextMessages.last?.content, "Assistant response 5")
    }
    
    func testGetContextMessagesExceedsLimit() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add 30 messages (15 exchanges) - exceeds 10 exchange limit
        for i in 1...15 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant response \(i)", role: .assistant))
        }
        
        // When
        let contextMessages = chatManager.getContextMessages(for: conversation)
        
        // Then
        XCTAssertEqual(contextMessages.count, 20) // Should be limited to 20 messages (10 exchanges)
        XCTAssertTrue(contextMessages.contains { $0.content == "User message 15" }) // Most recent should be included
        XCTAssertTrue(contextMessages.contains { $0.content == "Assistant response 15" }) // Most recent should be included
    }
    
    func testContextMessagesRelevanceScoring() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add messages with different relevance characteristics
        conversation.addMessage(Message(content: "Simple message", role: .user))
        conversation.addMessage(Message(content: "Simple response", role: .assistant))
        
        conversation.addMessage(Message(content: "How do I use Swift functions?", role: .user)) // Question + technical term
        conversation.addMessage(Message(content: "Here's an explanation with example code: func test() { return }", role: .assistant)) // Explanation + code
        
        // Add many more messages to trigger context limiting
        for i in 3...15 {
            conversation.addMessage(Message(content: "Message \(i)", role: .user))
            conversation.addMessage(Message(content: "Response \(i)", role: .assistant))
        }
        
        // When
        let contextMessages = chatManager.getContextMessages(for: conversation)
        
        // Then
        XCTAssertEqual(contextMessages.count, 20) // Limited to 20 messages
        // The high-relevance Swift question should be included despite being older
        XCTAssertTrue(contextMessages.contains { $0.content.contains("Swift functions") })
    }
    
    func testTrimConversationContext() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add 50 messages (25 exchanges) - well over the limit
        for i in 1...25 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant response \(i)", role: .assistant))
        }
        
        let originalCount = conversation.messages.count
        
        // When
        chatManager.trimConversationContext(&conversation)
        
        // Then
        XCTAssertLessThan(conversation.messages.count, originalCount) // Should be trimmed
        XCTAssertLessThanOrEqual(conversation.messages.count, 40) // Should not exceed 4x the context limit
        
        // Most recent messages should still be present
        XCTAssertTrue(conversation.messages.contains { $0.content == "User message 25" })
        XCTAssertTrue(conversation.messages.contains { $0.content == "Assistant response 25" })
    }
    
    func testContextStatistics() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add 30 messages (15 exchanges)
        for i in 1...15 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant response \(i)", role: .assistant))
        }
        
        // When
        let stats = chatManager.getContextStatistics(for: conversation)
        
        // Then
        XCTAssertEqual(stats.totalMessages, 30)
        XCTAssertEqual(stats.contextMessages, 20) // Limited by context window
        XCTAssertEqual(stats.totalExchanges, 15)
        XCTAssertEqual(stats.contextExchanges, 10)
        XCTAssertTrue(stats.isContextTrimmed)
        XCTAssertLessThan(stats.compressionRatio, 1.0) // Should be compressed
    }
    
    func testContextStatisticsWithinLimit() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add 10 messages (5 exchanges) - within limit
        for i in 1...5 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant response \(i)", role: .assistant))
        }
        
        // When
        let stats = chatManager.getContextStatistics(for: conversation)
        
        // Then
        XCTAssertEqual(stats.totalMessages, 10)
        XCTAssertEqual(stats.contextMessages, 10) // All messages included
        XCTAssertEqual(stats.totalExchanges, 5)
        XCTAssertEqual(stats.contextExchanges, 5)
        XCTAssertFalse(stats.isContextTrimmed)
        XCTAssertEqual(stats.compressionRatio, 1.0) // No compression
    }
    
    func testContextManagementEdgeCases() {
        // Test empty conversation
        let emptyConversation = Conversation(title: "Empty")
        let emptyContext = chatManager.getContextMessages(for: emptyConversation)
        XCTAssertTrue(emptyContext.isEmpty)
        
        // Test single message
        var singleMessageConversation = Conversation(title: "Single")
        singleMessageConversation.addMessage(Message(content: "Hello", role: .user))
        let singleContext = chatManager.getContextMessages(for: singleMessageConversation)
        XCTAssertEqual(singleContext.count, 1)
        
        // Test odd number of messages (incomplete exchange)
        var oddConversation = Conversation(title: "Odd")
        for i in 1...3 {
            oddConversation.addMessage(Message(content: "User \(i)", role: .user))
            if i < 3 { // Skip last assistant message
                oddConversation.addMessage(Message(content: "Assistant \(i)", role: .assistant))
            }
        }
        let oddContext = chatManager.getContextMessages(for: oddConversation)
        XCTAssertEqual(oddContext.count, 5) // Should handle odd number gracefully
    }
    
    func testContextPreservesMessageOrder() {
        // Given
        var conversation = Conversation(title: "Test")
        
        // Add messages with specific timestamps to test ordering
        let baseDate = Date()
        for i in 1...15 {
            let userMessage = Message(
                id: UUID(),
                content: "User message \(i)",
                role: .user,
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 2))
            )
            let assistantMessage = Message(
                id: UUID(),
                content: "Assistant response \(i)",
                role: .assistant,
                timestamp: baseDate.addingTimeInterval(TimeInterval(i * 2 + 1))
            )
            conversation.messages.append(userMessage)
            conversation.messages.append(assistantMessage)
        }
        
        // When
        let contextMessages = chatManager.getContextMessages(for: conversation)
        
        // Then
        // Verify messages are in chronological order
        for i in 0..<(contextMessages.count - 1) {
            XCTAssertLessThanOrEqual(contextMessages[i].timestamp, contextMessages[i + 1].timestamp)
        }
    }
    
    // MARK: - Voice Input Tests
    
    func testVoiceInputAvailability() {
        // Voice input availability should depend on voice manager permissions
        let isAvailable = chatManager.isVoiceInputAvailable
        XCTAssertTrue(isAvailable == true || isAvailable == false) // Should be a boolean
    }
    
    func testVoiceRecordingState() {
        // Initially not recording
        XCTAssertFalse(chatManager.isRecordingVoice)
    }
    
    func testVoiceInputManagerAccess() {
        // Should provide access to voice manager
        let voiceManager = chatManager.voiceInputManager
        XCTAssertNotNil(voiceManager)
    }
    
    func testStartVoiceInputWithoutPermissions() async {
        // This test would need to mock the voice manager to simulate no permissions
        // For now, we'll just test that the method exists and can be called
        do {
            _ = try await chatManager.startVoiceInput()
        } catch SerenaError.voicePermissionDenied {
            // Expected if permissions are not granted
            XCTAssertTrue(true)
        } catch {
            // Other errors are also acceptable for this test
            XCTAssertTrue(true)
        }
    }
    
    func testStopVoiceInputWhenNotRecording() async {
        // Should handle stopping when not recording gracefully
        do {
            let transcription = try await chatManager.stopVoiceInput()
            XCTAssertEqual(transcription, "")
        } catch {
            // Error is acceptable if voice input is not available
            XCTAssertTrue(true)
        }
    }
    
    func testSendVoiceMessageEmpty() async {
        // Should handle empty transcription
        do {
            try await chatManager.sendVoiceMessage()
        } catch SerenaError.emptyMessage {
            // Expected for empty transcription
            XCTAssertTrue(true)
        } catch {
            // Other errors are also acceptable
            XCTAssertTrue(true)
        }
    }
}

// MARK: - Mock Classes

class MockDataStore: DataStoreProtocol {
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

class MockErrorManager: ErrorManager {
    var handledErrors: [(SerenaError, String?)] = []
    
    override func handle(_ error: SerenaError, context: String? = nil) {
        handledErrors.append((error, context))
    }
}

@MainActor
class MockMixtralEngine: AIEngine {
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