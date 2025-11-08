import XCTest
@testable import SerenaNet

final class MessageTests: XCTestCase {
    
    func testMessageInitialization() {
        let message = Message(content: "Hello, world!", role: .user)
        
        XCTAssertEqual(message.content, "Hello, world!")
        XCTAssertEqual(message.role, .user)
        XCTAssertNotNil(message.id)
        XCTAssertTrue(message.timestamp.timeIntervalSinceNow < 1.0)
    }
    
    func testMessageRoleDisplayNames() {
        XCTAssertEqual(MessageRole.user.displayName, "You")
        XCTAssertEqual(MessageRole.assistant.displayName, "SerenaNet")
    }
    
    func testMessageEquality() {
        let id = UUID()
        let timestamp = Date()
        
        let message1 = Message(id: id, content: "Test", role: .user, timestamp: timestamp)
        let message2 = Message(id: id, content: "Test", role: .user, timestamp: timestamp)
        
        XCTAssertEqual(message1, message2)
    }
    
    func testMessageCodable() throws {
        let originalMessage = Message(content: "Test message", role: .assistant)
        
        let encoded = try JSONEncoder().encode(originalMessage)
        let decodedMessage = try JSONDecoder().decode(Message.self, from: encoded)
        
        XCTAssertEqual(originalMessage, decodedMessage)
    }
}