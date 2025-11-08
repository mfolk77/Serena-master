import Foundation
import SQLite
import CryptoKit

class DataStore {
    private var db: Connection?
    private let encryption: EncryptionManager
    
    // Table definitions
    private let conversations = Table("conversations")
    private let messages = Table("messages")
    private let userConfig = Table("user_config")
    
    // Conversation columns
    private let convId = Expression<String>("id")
    private let convTitle = Expression<Data>("title") // Encrypted
    private let convCreatedAt = Expression<Date>("created_at")
    private let convUpdatedAt = Expression<Date>("updated_at")
    
    // Message columns
    private let msgId = Expression<String>("id")
    private let msgConversationId = Expression<String>("conversation_id")
    private let msgContent = Expression<Data>("content") // Encrypted
    private let msgRole = Expression<String>("role")
    private let msgTimestamp = Expression<Date>("timestamp")
    
    // User config columns
    private let configKey = Expression<String>("key")
    private let configValue = Expression<Data>("value") // Encrypted
    
    init() throws {
        self.encryption = try EncryptionManager()
        try setupDatabase()
    }
    
    private func setupDatabase() throws {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let dbPath = documentsPath.appendingPathComponent("serenanet.db")
        
        db = try Connection(dbPath.path)
        try createTables()
    }
    
    private func createTables() throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        // Create conversations table
        try db.run(conversations.create(ifNotExists: true) { t in
            t.column(convId, primaryKey: true)
            t.column(convTitle)
            t.column(convCreatedAt)
            t.column(convUpdatedAt)
        })
        
        // Create messages table
        try db.run(messages.create(ifNotExists: true) { t in
            t.column(msgId, primaryKey: true)
            t.column(msgConversationId)
            t.column(msgContent)
            t.column(msgRole)
            t.column(msgTimestamp)
            t.foreignKey(msgConversationId, references: conversations, convId, delete: .cascade)
        })
        
        // Create user config table
        try db.run(userConfig.create(ifNotExists: true) { t in
            t.column(configKey, primaryKey: true)
            t.column(configValue)
        })
        
        // Create indexes for better performance
        try db.run(messages.createIndex(msgConversationId, ifNotExists: true))
        try db.run(messages.createIndex(msgTimestamp, ifNotExists: true))
    }
}

// MARK: - Conversation Operations
extension DataStore {
    func saveConversation(_ conversation: Conversation) async throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        let encryptedTitle = try encryption.encrypt(conversation.title)
        
        try db.run(conversations.insert(or: .replace,
            convId <- conversation.id.uuidString,
            convTitle <- encryptedTitle,
            convCreatedAt <- conversation.createdAt,
            convUpdatedAt <- conversation.updatedAt
        ))
        
        // Save all messages for this conversation
        for message in conversation.messages {
            try await saveMessage(message, conversationId: conversation.id)
        }
    }
    
    func loadConversations() async throws -> [Conversation] {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        var loadedConversations: [Conversation] = []
        
        for row in try db.prepare(conversations.order(convUpdatedAt.desc)) {
            let id = UUID(uuidString: row[convId])!
            let title = try encryption.decryptString(row[convTitle])
            let createdAt = row[convCreatedAt]
            let updatedAt = row[convUpdatedAt]
            
            let conversationMessages = try await loadMessages(for: id)
            
            let conversation = Conversation(
                id: id,
                title: title,
                messages: conversationMessages,
                createdAt: createdAt,
                updatedAt: updatedAt
            )
            
            loadedConversations.append(conversation)
        }
        
        return loadedConversations
    }
    
    func deleteConversation(id: UUID) async throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        let conversation = conversations.filter(convId == id.uuidString)
        try db.run(conversation.delete())
    }
    
    private func saveMessage(_ message: Message, conversationId: UUID) async throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        let encryptedContent = try encryption.encrypt(message.content)
        
        try db.run(messages.insert(or: .replace,
            msgId <- message.id.uuidString,
            msgConversationId <- conversationId.uuidString,
            msgContent <- encryptedContent,
            msgRole <- message.role.rawValue,
            msgTimestamp <- message.timestamp
        ))
    }
    
    private func loadMessages(for conversationId: UUID) async throws -> [Message] {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        var loadedMessages: [Message] = []
        
        let query = messages
            .filter(msgConversationId == conversationId.uuidString)
            .order(msgTimestamp.asc)
        
        for row in try db.prepare(query) {
            let id = UUID(uuidString: row[msgId])!
            let content = try encryption.decryptString(row[msgContent])
            let role = MessageRole(rawValue: row[msgRole])!
            let timestamp = row[msgTimestamp]
            
            let message = Message(
                id: id,
                content: content,
                role: role,
                timestamp: timestamp
            )
            
            loadedMessages.append(message)
        }
        
        return loadedMessages
    }
}

// MARK: - User Config Operations
extension DataStore {
    func saveUserConfig(_ config: UserConfig) async throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        let configData = try JSONEncoder().encode(config)
        let encryptedData = try encryption.encrypt(configData)
        
        try db.run(userConfig.insert(or: .replace,
            configKey <- "user_config",
            configValue <- encryptedData
        ))
    }
    
    func loadUserConfig() async throws -> UserConfig {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        let query = userConfig.filter(configKey == "user_config")
        
        if let row = try db.pluck(query) {
            let decryptedData = try encryption.decryptData(row[configValue])
            return try JSONDecoder().decode(UserConfig.self, from: decryptedData)
        } else {
            // Return default config if none exists
            let defaultConfig = UserConfig.default
            try await saveUserConfig(defaultConfig)
            return defaultConfig
        }
    }
}

// MARK: - Utility Operations
extension DataStore {
    func clearAllData() async throws {
        guard let db = db else { throw DataStoreError.databaseNotInitialized }
        
        try db.run(messages.delete())
        try db.run(conversations.delete())
        try db.run(userConfig.delete())
    }
    
    func getDatabaseSize() throws -> Int64 {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                                   in: .userDomainMask).first!
        let dbPath = documentsPath.appendingPathComponent("serenanet.db")
        
        let attributes = try FileManager.default.attributesOfItem(atPath: dbPath.path)
        return attributes[.size] as? Int64 ?? 0
    }
}

// MARK: - Error Types
enum DataStoreError: LocalizedError {
    case databaseNotInitialized
    case encryptionFailed
    case decryptionFailed
    case invalidData
    
    var errorDescription: String? {
        switch self {
        case .databaseNotInitialized:
            return "Database connection not initialized"
        case .encryptionFailed:
            return "Failed to encrypt data"
        case .decryptionFailed:
            return "Failed to decrypt data"
        case .invalidData:
            return "Invalid data format"
        }
    }
}