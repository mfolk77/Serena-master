import XCTest
@testable import SerenaNet

final class ConversationTests: XCTestCase {
    
    func testConversationInitialization() {
        let conversation = Conversation()
        
        XCTAssertEqual(conversation.title, "New Conversation")
        XCTAssertTrue(conversation.messages.isEmpty)
        XCTAssertNotNil(conversation.id)
        XCTAssertTrue(conversation.isEmpty)
    }
    
    func testAddMessage() {
        var conversation = Conversation()
        let message = Message(content: "Hello", role: .user)
        
        conversation.addMessage(message)
        
        XCTAssertEqual(conversation.messages.count, 1)
        XCTAssertEqual(conversation.messages.first, message)
        XCTAssertFalse(conversation.isEmpty)
        XCTAssertEqual(conversation.lastMessage, message)
    }
    
    func testAutoTitleGeneration() {
        var conversation = Conversation()
        let userMessage = Message(content: "What is the weather like today?", role: .user)
        
        conversation.addMessage(userMessage)
        
        XCTAssertEqual(conversation.title, "What is the weather like today?")
    }
    
    func testAutoTitleTruncation() {
        var conversation = Conversation()
        let longContent = String(repeating: "a", count: 60)
        let userMessage = Message(content: longContent, role: .user)
        
        conversation.addMessage(userMessage)
        
        XCTAssertTrue(conversation.title.hasSuffix("..."))
        XCTAssertEqual(conversation.title.count, 53) // 50 chars + "..."
    }
    
    func testGetContextMessages() {
        var conversation = Conversation()
        
        // Add 15 messages (more than the default limit of 10 exchanges = 20 messages)
        for i in 1...15 {
            conversation.addMessage(Message(content: "User message \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant message \(i)", role: .assistant))
        }
        
        let contextMessages = conversation.getContextMessages()
        
        // Should return last 20 messages (10 exchanges)
        XCTAssertEqual(contextMessages.count, 20)
        XCTAssertTrue(contextMessages.first?.content.contains("User message 6") ?? false)
        XCTAssertTrue(contextMessages.last?.content.contains("Assistant message 15") ?? false)
    }
    
    func testGetContextMessagesWithCustomLimit() {
        var conversation = Conversation()
        
        for i in 1...10 {
            conversation.addMessage(Message(content: "User \(i)", role: .user))
            conversation.addMessage(Message(content: "Assistant \(i)", role: .assistant))
        }
        
        let contextMessages = conversation.getContextMessages(limit: 3)
        
        // Should return last 6 messages (3 exchanges)
        XCTAssertEqual(contextMessages.count, 6)
    }
    
    func testConversationCodable() throws {
        var conversation = Conversation(title: "Test Conversation")
        conversation.addMessage(Message(content: "Hello", role: .user))
        conversation.addMessage(Message(content: "Hi there!", role: .assistant))
        
        let encoded = try JSONEncoder().encode(conversation)
        let decoded = try JSONDecoder().decode(Conversation.self, from: encoded)
        
        XCTAssertEqual(conversation, decoded)
    }
}