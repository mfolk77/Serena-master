import XCTest
@testable import SerenaNet

final class DataStoreTests: XCTestCase {
    var dataStore: DataStore!
    
    override func setUp() async throws {
        try await super.setUp()
        dataStore = try DataStore()
        try await dataStore.clearAllData() // Start with clean slate
    }
    
    override func tearDown() async throws {
        try await dataStore.clearAllData()
        try await super.tearDown()
    }
    
    func testSaveAndLoadConversation() async throws {
        var conversation = Conversation(title: "Test Conversation")
        conversation.addMessage(Message(content: "Hello", role: .user))
        conversation.addMessage(Message(content: "Hi there!", role: .assistant))
        
        try await dataStore.saveConversation(conversation)
        
        let loadedConversations = try await dataStore.loadConversations()
        
        XCTAssertEqual(loadedConversations.count, 1)
        let loadedConversation = loadedConversations.first!
        
        XCTAssertEqual(loadedConversation.id, conversation.id)
        XCTAssertEqual(loadedConversation.title, conversation.title)
        XCTAssertEqual(loadedConversation.messages.count, 2)
        XCTAssertEqual(loadedConversation.messages[0].content, "Hello")
        XCTAssertEqual(loadedConversation.messages[1].content, "Hi there!")
    }
    
    func testDeleteConversation() async throws {
        var conversation = Conversation(title: "Test Conversation")
        conversation.addMessage(Message(content: "Hello", role: .user))
        
        try await dataStore.saveConversation(conversation)
        
        var loadedConversations = try await dataStore.loadConversations()
        XCTAssertEqual(loadedConversations.count, 1)
        
        try await dataStore.deleteConversation(id: conversation.id)
        
        loadedConversations = try await dataStore.loadConversations()
        XCTAssertEqual(loadedConversations.count, 0)
    }
    
    func testSaveAndLoadUserConfig() async throws {
        let config = UserConfig(
            nickname: "TestUser",
            theme: .dark,
            voiceInputEnabled: false,
            passcodeEnabled: true,
            aiParameters: AIParameters(temperature: 0.5, maxTokens: 500, contextWindow: 5)
        )
        
        try await dataStore.saveUserConfig(config)
        let loadedConfig = try await dataStore.loadUserConfig()
        
        XCTAssertEqual(loadedConfig, config)
    }
    
    func testLoadDefaultUserConfig() async throws {
        // Should return default config when none exists
        let loadedConfig = try await dataStore.loadUserConfig()
        XCTAssertEqual(loadedConfig, UserConfig.default)
    }
    
    func testMultipleConversationsOrdering() async throws {
        // Create conversations with different update times
        var conv1 = Conversation(title: "First")
        var conv2 = Conversation(title: "Second") 
        var conv3 = Conversation(title: "Third")
        
        // Manually set different update times to ensure ordering
        let baseTime = Date()
        conv1 = Conversation(id: conv1.id, title: conv1.title, messages: conv1.messages, 
                           createdAt: conv1.createdAt, updatedAt: baseTime)
        conv2 = Conversation(id: conv2.id, title: conv2.title, messages: conv2.messages,
                           createdAt: conv2.createdAt, updatedAt: baseTime.addingTimeInterval(1))
        conv3 = Conversation(id: conv3.id, title: conv3.title, messages: conv3.messages,
                           createdAt: conv3.createdAt, updatedAt: baseTime.addingTimeInterval(2))
        
        try await dataStore.saveConversation(conv1)
        try await dataStore.saveConversation(conv2)
        try await dataStore.saveConversation(conv3)
        
        let loadedConversations = try await dataStore.loadConversations()
        
        XCTAssertEqual(loadedConversations.count, 3)
        // Should be ordered by updatedAt desc (most recent first)
        XCTAssertEqual(loadedConversations[0].title, "Third")
        XCTAssertEqual(loadedConversations[1].title, "Second")
        XCTAssertEqual(loadedConversations[2].title, "First")
    }
    
    func testClearAllData() async throws {
        // Add some data
        let conversation = Conversation(title: "Test")
        try await dataStore.saveConversation(conversation)
        
        let config = UserConfig(nickname: "Test")
        try await dataStore.saveUserConfig(config)
        
        // Verify data exists
        var loadedConversations = try await dataStore.loadConversations()
        XCTAssertEqual(loadedConversations.count, 1)
        
        // Clear all data
        try await dataStore.clearAllData()
        
        // Verify data is gone
        loadedConversations = try await dataStore.loadConversations()
        XCTAssertEqual(loadedConversations.count, 0)
        
        // User config should return to default
        let loadedConfig = try await dataStore.loadUserConfig()
        XCTAssertEqual(loadedConfig, UserConfig.default)
    }
    
    func testEncryptionIntegrity() async throws {
        // Test that sensitive data is actually encrypted by trying to find plain text
        let sensitiveContent = "This is sensitive information that should be encrypted"
        var conversation = Conversation(title: sensitiveContent)
        conversation.addMessage(Message(content: sensitiveContent, role: .user))
        
        try await dataStore.saveConversation(conversation)
        
        // Get the raw database file and check it doesn't contain plain text
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let dbPath = documentsPath.appendingPathComponent("serenanet.db")
        
        let dbData = try Data(contentsOf: dbPath)
        let dbString = String(data: dbData, encoding: .utf8) ?? ""
        
        // The sensitive content should not appear in plain text in the database file
        XCTAssertFalse(dbString.contains(sensitiveContent))
        
        // But we should still be able to decrypt and retrieve it
        let loadedConversations = try await dataStore.loadConversations()
        XCTAssertEqual(loadedConversations.first?.title, sensitiveContent)
        XCTAssertEqual(loadedConversations.first?.messages.first?.content, sensitiveContent)
    }
}