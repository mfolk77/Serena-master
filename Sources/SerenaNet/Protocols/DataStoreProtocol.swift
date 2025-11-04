import Foundation

protocol DataStoreProtocol {
    func loadConversations() async throws -> [Conversation]
    func saveConversation(_ conversation: Conversation) async throws
    func deleteConversation(id: UUID) async throws
    func clearAllData() async throws
}

// Make DataStore conform to the protocol
extension DataStore: DataStoreProtocol {
    // Methods are already implemented in the DataStore extensions
}