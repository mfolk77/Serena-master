import Foundation

struct Message: Identifiable, Codable, Equatable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
    
    init(content: String, role: MessageRole) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
    }
    
    init(id: UUID, content: String, role: MessageRole, timestamp: Date) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}

enum MessageRole: String, Codable, CaseIterable {
    case user
    case assistant
    
    var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "SerenaNet"
        }
    }
}