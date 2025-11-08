// MARK: - Memory System Components

class ShortTermMemory: ObservableObject {
    @Published var memory: [ShortTermMemoryItem] = []
    private let memoryLimit = 20 // Maximum number of items to keep
    func addItem(_ content: String) {
        memory.append(ShortTermMemoryItem(id: UUID(), content: content, timestamp: Date()))
    }
}

struct ShortTermMemoryItem: Identifiable, Codable {
    let id: UUID
    let content: String
    let timestamp: Date
}

struct LongTermMemoryItem: Identifiable, Codable {
    let id: UUID
    let key: String
    let value: String
    let timestamp: Date
}

struct Message: Codable, Identifiable {
    var id: UUID = UUID()
    var timestamp: Date
    var role: String          // "user" or "ai"
    var content: String
    var isUserMessage: Bool
    init(timestamp: Date = .now, role: String, content: String) {
        self.timestamp = timestamp
        self.role = role
        self.content = content
        self.isUserMessage = (role.lowercased() == "user")
    }
}

struct Conversation: Codable, Identifiable {
    var id: String
    var title: String
    var messages: [Message]
    var timestamp: Date
} 