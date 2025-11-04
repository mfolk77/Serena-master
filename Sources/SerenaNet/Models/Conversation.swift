import Foundation

struct Conversation: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
    
    init(title: String = "New Conversation") {
        self.id = UUID()
        self.title = title
        self.messages = []
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    init(id: UUID, title: String, messages: [Message], createdAt: Date, updatedAt: Date) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
    
    mutating func addMessage(_ message: Message) {
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
    func getContextMessages(limit: Int = 10) -> [Message] {
        let maxMessages = limit * 2 // Each exchange is user + assistant
        return Array(messages.suffix(maxMessages))
    }
    
    var isEmpty: Bool {
        return messages.isEmpty
    }
    
    var lastMessage: Message? {
        return messages.last
    }
}