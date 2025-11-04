import Foundation

public struct Conversation: Identifiable, Codable, Equatable {
    public let id: UUID
    public var title: String
    public var messages: [Message]
    public let createdAt: Date
    public var updatedAt: Date
    
    public init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public init(id: UUID, title: String, messages: [Message], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    public mutating func addMessage(_ message: Message) {
        messages.append(message)
        updatedAt = Date()
        
        // Auto-generate title from first user message if still default
        if title == "New Conversation", 
           let firstUserMessage = messages.first(where: { $0.role == .user }) {
            title = String(firstUserMessage.content.prefix(50))
            if firstUserMessage.content.count > 50 {
                title += "..."
            }
        }
    }
    
    /// Get the last N messages for context (up to 10 exchanges = 20 messages)
    public func getContextMessages(limit: Int = 10) -> [Message] {
        let maxMessages = limit * 2 // Each exchange is user + assistant
        return Array(messages.suffix(maxMessages))
    }
    
    public var isEmpty: Bool {
        return messages.isEmpty
    }
    
    public var lastMessage: Message? {
        return messages.last
    }
}