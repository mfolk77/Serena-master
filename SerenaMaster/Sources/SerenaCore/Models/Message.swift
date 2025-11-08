import Foundation

public struct Message: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let content: String
    public let role: MessageRole
    public let timestamp: Date
    
    public init(content: String, role: MessageRole) {
        self.id = UUID()
        self.content = content
        self.role = role
        self.timestamp = Date()
    }
    
    public init(id: UUID, content: String, role: MessageRole, timestamp: Date) {
        self.id = id
        self.content = content
        self.role = role
        self.timestamp = timestamp
    }
}

public enum MessageRole: String, Codable, CaseIterable, Sendable {
    case user
    case assistant
    
    public var displayName: String {
        switch self {
        case .user:
            return "You"
        case .assistant:
            return "SerenaNet"
        }
    }
}