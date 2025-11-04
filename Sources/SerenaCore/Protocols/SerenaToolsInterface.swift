import Foundation

/// Protocol defining the interface for SerenaTools integration
/// This provides the foundation for connecting SerenaNet MVP with the full SerenaTools ecosystem
@MainActor
public protocol SerenaToolsInterface: ObservableObject {
    
    // MARK: - Connection Management
    
    /// Whether SerenaTools is available and connected
    var isConnected: Bool { get }
    
    /// Current connection status
    var connectionStatus: SerenaToolsConnectionStatus { get }
    
    /// Initialize connection to SerenaTools
    func connect() async throws
    
    /// Disconnect from SerenaTools
    func disconnect() async
    
    // MARK: - Tool Discovery and Management
    
    /// List all available tools in the SerenaTools ecosystem
    func listAvailableTools() async throws -> [SerenaToolDescriptor]
    
    /// Check if a specific tool is available
    func isToolAvailable(_ toolName: String) async -> Bool
    
    /// Get detailed information about a specific tool
    func getToolInfo(_ toolName: String) async throws -> SerenaToolDescriptor
    
    // MARK: - Command Execution
    
    /// Execute a command using SerenaTools
    /// - Parameters:
    ///   - command: The command to execute
    ///   - context: Optional context from current conversation
    ///   - parameters: Additional parameters for the command
    /// - Returns: The result of the command execution
    func executeCommand(
        _ command: String,
        context: [Message]?,
        parameters: [String: Any]?
    ) async throws -> SerenaToolsResult
    
    /// Execute a command with streaming results
    /// - Parameters:
    ///   - command: The command to execute
    ///   - context: Optional context from current conversation
    ///   - parameters: Additional parameters for the command
    ///   - onUpdate: Callback for streaming updates
    /// - Returns: The final result of the command execution
    func executeCommandStreaming(
        _ command: String,
        context: [Message]?,
        parameters: [String: Any]?,
        onUpdate: @escaping (SerenaToolsStreamingUpdate) -> Void
    ) async throws -> SerenaToolsResult
    
    // MARK: - FTAI Integration
    
    /// Process an FTAI document using SerenaTools
    /// - Parameter document: The FTAI document to process
    /// - Returns: The processed result
    func processFTAIDocument(_ document: FTAIDocument) async throws -> SerenaToolsResult
    
    /// Validate an FTAI document against SerenaTools schemas
    /// - Parameter document: The FTAI document to validate
    /// - Returns: Validation result with any errors or warnings
    func validateFTAIDocument(_ document: FTAIDocument) async throws -> FTAIValidationResult
    
    // MARK: - Plugin Management
    
    /// Load a plugin into the SerenaTools environment
    /// - Parameter pluginPath: Path to the plugin to load
    func loadPlugin(at pluginPath: String) async throws
    
    /// Unload a plugin from the SerenaTools environment
    /// - Parameter pluginName: Name of the plugin to unload
    func unloadPlugin(_ pluginName: String) async throws
    
    /// List all loaded plugins
    func listLoadedPlugins() async -> [SerenaPluginDescriptor]
    
    // MARK: - Configuration
    
    /// Update SerenaTools configuration
    /// - Parameter configuration: New configuration to apply
    func updateConfiguration(_ configuration: SerenaToolsConfiguration) async throws
    
    /// Get current SerenaTools configuration
    func getConfiguration() async throws -> SerenaToolsConfiguration
}

// MARK: - Supporting Types

/// Connection status for SerenaTools
public enum SerenaToolsConnectionStatus: String, Codable, CaseIterable {
    case disconnected
    case connecting
    case connected
    case error
    
    public var description: String {
        switch self {
        case .disconnected:
            return "Disconnected"
        case .connecting:
            return "Connecting"
        case .connected:
            return "Connected"
        case .error:
            return "Connection Error"
        }
    }
}

/// Descriptor for a SerenaTools tool
public struct SerenaToolDescriptor: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let description: String
    public let version: String
    public let category: SerenaToolCategory
    public let capabilities: [String]
    public let requiredParameters: [String]
    public let optionalParameters: [String]
    public let isAvailable: Bool
    
    public init(
        id: String,
        name: String,
        description: String,
        version: String,
        category: SerenaToolCategory,
        capabilities: [String],
        requiredParameters: [String] = [],
        optionalParameters: [String] = [],
        isAvailable: Bool = true
    ) {
        self.id = id
        self.name = name
        self.description = description
        self.version = version
        self.category = category
        self.capabilities = capabilities
        self.requiredParameters = requiredParameters
        self.optionalParameters = optionalParameters
        self.isAvailable = isAvailable
    }
}

/// Categories for SerenaTools tools
public enum SerenaToolCategory: String, Codable, CaseIterable {
    case digitalEstate = "digital_estate"
    case businessTools = "business_tools"
    case aiOrchestration = "ai_orchestration"
    case dataManagement = "data_management"
    case security = "security"
    case productivity = "productivity"
    case integration = "integration"
    case development = "development"
    
    public var displayName: String {
        switch self {
        case .digitalEstate:
            return "Digital Estate"
        case .businessTools:
            return "Business Tools"
        case .aiOrchestration:
            return "AI Orchestration"
        case .dataManagement:
            return "Data Management"
        case .security:
            return "Security"
        case .productivity:
            return "Productivity"
        case .integration:
            return "Integration"
        case .development:
            return "Development"
        }
    }
}

/// Result from SerenaTools command execution
public struct SerenaToolsResult: Codable {
    public let success: Bool
    public let data: Data?
    public let message: String
    public let metadata: [String: String]
    public let executionTime: TimeInterval
    public let toolUsed: String
    
    public init(
        success: Bool,
        data: Data? = nil,
        message: String,
        metadata: [String: String] = [:],
        executionTime: TimeInterval,
        toolUsed: String
    ) {
        self.success = success
        self.data = data
        self.message = message
        self.metadata = metadata
        self.executionTime = executionTime
        self.toolUsed = toolUsed
    }
}

/// Streaming update from SerenaTools command execution
public struct SerenaToolsStreamingUpdate: Codable {
    public let type: UpdateType
    public let content: String
    public let progress: Double?
    public let metadata: [String: String]
    
    public enum UpdateType: String, Codable {
        case progress
        case data
        case warning
        case error
        case completion
    }
    
    public init(
        type: UpdateType,
        content: String,
        progress: Double? = nil,
        metadata: [String: String] = [:]
    ) {
        self.type = type
        self.content = content
        self.progress = progress
        self.metadata = metadata
    }
}

/// Plugin descriptor for SerenaTools plugins
public struct SerenaPluginDescriptor: Codable, Identifiable, Equatable {
    public let id: String
    public let name: String
    public let version: String
    public let description: String
    public let author: String
    public let isLoaded: Bool
    public let capabilities: [String]
    
    public init(
        id: String,
        name: String,
        version: String,
        description: String,
        author: String,
        isLoaded: Bool,
        capabilities: [String]
    ) {
        self.id = id
        self.name = name
        self.version = version
        self.description = description
        self.author = author
        self.isLoaded = isLoaded
        self.capabilities = capabilities
    }
}

/// Configuration for SerenaTools integration
public struct SerenaToolsConfiguration: Codable {
    public let connectionTimeout: TimeInterval
    public let maxConcurrentOperations: Int
    public let enabledCategories: [SerenaToolCategory]
    public let pluginDirectories: [String]
    public let securityLevel: SecurityLevel
    public let loggingEnabled: Bool
    
    public enum SecurityLevel: String, Codable, CaseIterable {
        case minimal
        case standard
        case enhanced
        case maximum
    }
    
    public init(
        connectionTimeout: TimeInterval = 30.0,
        maxConcurrentOperations: Int = 5,
        enabledCategories: [SerenaToolCategory] = SerenaToolCategory.allCases,
        pluginDirectories: [String] = [],
        securityLevel: SecurityLevel = .standard,
        loggingEnabled: Bool = true
    ) {
        self.connectionTimeout = connectionTimeout
        self.maxConcurrentOperations = maxConcurrentOperations
        self.enabledCategories = enabledCategories
        self.pluginDirectories = pluginDirectories
        self.securityLevel = securityLevel
        self.loggingEnabled = loggingEnabled
    }
    
    public static let `default` = SerenaToolsConfiguration()
}

/// FTAI document validation result
public struct FTAIValidationResult: Codable {
    public let isValid: Bool
    public let errors: [ValidationError]
    public let warnings: [ValidationWarning]
    public let suggestions: [String]
    
    public struct ValidationError: Codable {
        public let line: Int?
        public let column: Int?
        public let message: String
        public let severity: Severity
        
        public enum Severity: String, Codable {
            case error
            case warning
            case info
        }
        
        public init(line: Int? = nil, column: Int? = nil, message: String, severity: Severity) {
            self.line = line
            self.column = column
            self.message = message
            self.severity = severity
        }
    }
    
    public struct ValidationWarning: Codable {
        public let message: String
        public let suggestion: String?
        
        public init(message: String, suggestion: String? = nil) {
            self.message = message
            self.suggestion = suggestion
        }
    }
    
    public init(
        isValid: Bool,
        errors: [ValidationError] = [],
        warnings: [ValidationWarning] = [],
        suggestions: [String] = []
    ) {
        self.isValid = isValid
        self.errors = errors
        self.warnings = warnings
        self.suggestions = suggestions
    }
}