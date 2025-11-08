import Foundation

/// Protocol defining the interface for data storage operations
public protocol DataStoreProtocol {
    // MARK: - Conversation Operations
    func saveConversation(_ conversation: Conversation) async throws
    func loadConversations() async throws -> [Conversation]
    func deleteConversation(id: UUID) async throws
    
    // MARK: - User Config Operations
    func saveUserConfig(_ config: UserConfig) async throws
    func loadUserConfig() async throws -> UserConfig
    
    // MARK: - Utility Operations
    func clearAllData() async throws
    func getDatabaseSize() throws -> Int64
}

/// Protocol for platform-specific data store implementations
public protocol PlatformDataStore: DataStoreProtocol {
    /// Initialize the data store for the specific platform
    init(platform: PlatformManager.Platform) throws
    
    /// Get the platform-specific storage location
    var storageLocation: URL { get }
    
    /// Check if the data store supports encryption
    var supportsEncryption: Bool { get }
    
    /// Perform platform-specific optimizations
    func optimizeForPlatform() async throws
}

/// Factory for creating platform-appropriate data stores
public class DataStoreFactory {
    public static func createDataStore() throws -> DataStoreProtocol {
        let platform = PlatformManager.shared.currentPlatform
        
        switch platform {
        case .macOS:
            return try MacOSDataStore(platform: platform)
        case .iOS, .iPadOS:
            return try IOSDataStore(platform: platform)
        case .unknown:
            return try DefaultDataStore(platform: platform)
        }
    }
}

// MARK: - Platform-Specific Implementations

/// macOS-specific data store implementation
public class MacOSDataStore: PlatformDataStore {
    private let baseDataStore: DataStore
    
    public required init(platform: PlatformManager.Platform) throws {
        self.baseDataStore = try DataStore()
    }
    
    public var storageLocation: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        return appSupport.appendingPathComponent("SerenaNet")
    }
    
    public var supportsEncryption: Bool { true }
    
    public func optimizeForPlatform() async throws {
        // macOS-specific optimizations
        // Enable WAL mode for better concurrent access
        // Set up file system monitoring
    }
    
    // Delegate to base implementation
    public func saveConversation(_ conversation: Conversation) async throws {
        try await baseDataStore.saveConversation(conversation)
    }
    
    public func loadConversations() async throws -> [Conversation] {
        try await baseDataStore.loadConversations()
    }
    
    public func deleteConversation(id: UUID) async throws {
        try await baseDataStore.deleteConversation(id: id)
    }
    
    public func saveUserConfig(_ config: UserConfig) async throws {
        try await baseDataStore.saveUserConfig(config)
    }
    
    public func loadUserConfig() async throws -> UserConfig {
        try await baseDataStore.loadUserConfig()
    }
    
    public func clearAllData() async throws {
        try await baseDataStore.clearAllData()
    }
    
    public func getDatabaseSize() throws -> Int64 {
        try baseDataStore.getDatabaseSize()
    }
}

/// iOS/iPadOS-specific data store implementation
public class IOSDataStore: PlatformDataStore {
    private let baseDataStore: DataStore
    
    public required init(platform: PlatformManager.Platform) throws {
        self.baseDataStore = try DataStore()
    }
    
    public var storageLocation: URL {
        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documents.appendingPathComponent("SerenaNet")
    }
    
    public var supportsEncryption: Bool { true }
    
    public func optimizeForPlatform() async throws {
        // iOS-specific optimizations
        // Configure for app backgrounding
        // Set up data protection classes
        // Optimize for lower memory usage
    }
    
    // Delegate to base implementation
    public func saveConversation(_ conversation: Conversation) async throws {
        try await baseDataStore.saveConversation(conversation)
    }
    
    public func loadConversations() async throws -> [Conversation] {
        try await baseDataStore.loadConversations()
    }
    
    public func deleteConversation(id: UUID) async throws {
        try await baseDataStore.deleteConversation(id: id)
    }
    
    public func saveUserConfig(_ config: UserConfig) async throws {
        try await baseDataStore.saveUserConfig(config)
    }
    
    public func loadUserConfig() async throws -> UserConfig {
        try await baseDataStore.loadUserConfig()
    }
    
    public func clearAllData() async throws {
        try await baseDataStore.clearAllData()
    }
    
    public func getDatabaseSize() throws -> Int64 {
        try baseDataStore.getDatabaseSize()
    }
}

/// Default data store for unknown platforms
public class DefaultDataStore: PlatformDataStore {
    private let baseDataStore: DataStore
    
    public required init(platform: PlatformManager.Platform) throws {
        self.baseDataStore = try DataStore()
    }
    
    public var storageLocation: URL {
        let temp = FileManager.default.temporaryDirectory
        return temp.appendingPathComponent("SerenaNet")
    }
    
    public var supportsEncryption: Bool { false }
    
    public func optimizeForPlatform() async throws {
        // No platform-specific optimizations
    }
    
    // Delegate to base implementation
    public func saveConversation(_ conversation: Conversation) async throws {
        try await baseDataStore.saveConversation(conversation)
    }
    
    public func loadConversations() async throws -> [Conversation] {
        try await baseDataStore.loadConversations()
    }
    
    public func deleteConversation(id: UUID) async throws {
        try await baseDataStore.deleteConversation(id: id)
    }
    
    public func saveUserConfig(_ config: UserConfig) async throws {
        try await baseDataStore.saveUserConfig(config)
    }
    
    public func loadUserConfig() async throws -> UserConfig {
        try await baseDataStore.loadUserConfig()
    }
    
    public func clearAllData() async throws {
        try await baseDataStore.clearAllData()
    }
    
    public func getDatabaseSize() throws -> Int64 {
        try baseDataStore.getDatabaseSize()
    }
}