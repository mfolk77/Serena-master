# SerenaNet MVP - AI Assistant Design

**Created:** July 30, 2025 - Wednesday

## Overview

SerenaNet MVP is a local AI assistant built with SwiftUI for macOS, designed for future iPad deployment. The architecture prioritizes simplicity, Apple compliance, and offline functionality while maintaining extensibility for future SerenaTools integration.

## Architecture

### High-Level Architecture

```
┌─────────────────┐    ┌─────────────────┐    ┌─────────────────┐
│   SwiftUI Views │    │  Business Logic │    │  Data & AI      │
│                 │    │                 │    │                 │
│ • ChatView      │◄──►│ • ChatManager   │◄──►│ • MixtralEngine │
│ • SettingsView  │    │ • VoiceManager  │    │ • DataStore     │
│ • ConfigView    │    │ • ConfigManager │    │ • FTAIParser    │
└─────────────────┘    └─────────────────┘    └─────────────────┘
```

### Core Components

1. **Presentation Layer** (SwiftUI)
   - ChatView: Main conversation interface
   - SettingsView: User preferences and configuration
   - VoiceInputView: Voice recording interface

2. **Business Logic Layer**
   - ChatManager: Orchestrates conversations and AI interactions
   - VoiceManager: Handles speech-to-text processing
   - ConfigManager: Manages user settings and preferences

3. **Data Layer**
   - MixtralEngine: Local AI model interface
   - DataStore: SQLite database with encryption
   - FTAIParser: Handles .ftai file parsing

## Components and Interfaces

### ChatManager

```swift
@MainActor
class ChatManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isProcessing: Bool = false
    
    private let aiEngine: MixtralEngine
    private let dataStore: DataStore
    private let voiceManager: VoiceManager
    
    func sendMessage(_ text: String) async
    func startVoiceInput() async
    func createNewConversation()
    func loadConversations()
}
```

### MixtralEngine

```swift
protocol AIEngine {
    func initialize() async throws
    func generateResponse(for prompt: String, context: [Message]) async throws -> String
    var isReady: Bool { get }
    var memoryUsage: Int { get }
}

class MixtralEngine: AIEngine {
    private var model: MLModel?
    private let maxContextLength = 10 // 10 prior exchanges
    
    func initialize() async throws
    func generateResponse(for prompt: String, context: [Message]) async throws -> String
}
```

### VoiceManager

```swift
class VoiceManager: ObservableObject {
    @Published var isRecording: Bool = false
    @Published var transcription: String = ""
    
    private let speechRecognizer: SFSpeechRecognizer
    
    func startRecording() async throws
    func stopRecording() async throws -> String
    func requestPermissions() async -> Bool
}
```

### DataStore

```swift
class DataStore {
    private let database: SQLiteDatabase
    private let encryption: EncryptionManager
    
    func saveConversation(_ conversation: Conversation) async throws
    func loadConversations() async throws -> [Conversation]
    func deleteConversation(id: UUID) async throws
    func clearAllData() async throws
}
```

## Data Models

### Core Models

```swift
struct Conversation: Identifiable, Codable {
    let id: UUID
    var title: String
    var messages: [Message]
    let createdAt: Date
    var updatedAt: Date
}

struct Message: Identifiable, Codable {
    let id: UUID
    let content: String
    let role: MessageRole
    let timestamp: Date
}

enum MessageRole: String, Codable {
    case user
    case assistant
}

struct UserConfig: Codable {
    var nickname: String = "User"
    var theme: AppTheme = .system
    var voiceInputEnabled: Bool = true
    var passcodeEnabled: Bool = false
    var aiParameters: AIParameters = AIParameters()
}

struct AIParameters: Codable {
    var temperature: Double = 0.7
    var maxTokens: Int = 1000
    var contextWindow: Int = 10
}
```

### FTAI Support

```swift
struct FTAIDocument: Codable {
    let version: String
    let metadata: [String: Any]
    let content: String
    let schema: FTAISchema?
}

class FTAIParser {
    func parse(_ content: String) throws -> FTAIDocument
    func validate(_ document: FTAIDocument) throws -> Bool
}
```

## Error Handling

### Error Types

```swift
enum SerenaError: LocalizedError {
    case aiModelNotLoaded
    case voicePermissionDenied
    case databaseError(String)
    case networkUnavailable
    case invalidFTAIFormat
    
    var errorDescription: String? {
        switch self {
        case .aiModelNotLoaded:
            return "AI model is not ready. Please wait for initialization."
        case .voicePermissionDenied:
            return "Voice input requires microphone permission."
        case .databaseError(let message):
            return "Database error: \(message)"
        case .networkUnavailable:
            return "Network unavailable, but local AI continues working."
        case .invalidFTAIFormat:
            return "Invalid FTAI file format."
        }
    }
}
```

### Error Recovery

```swift
class ErrorManager {
    func handle(_ error: SerenaError) -> ErrorRecoveryAction
    func logError(_ error: Error, context: String)
    func showUserFriendlyMessage(for error: SerenaError)
}

enum ErrorRecoveryAction {
    case retry
    case fallback
    case userIntervention(String)
    case ignore
}
```

## Testing Strategy

### Unit Tests
- **ChatManager**: Message handling, conversation management
- **MixtralEngine**: AI response generation, context management
- **VoiceManager**: Speech recognition, permission handling
- **DataStore**: Database operations, encryption
- **FTAIParser**: File parsing, validation

### Integration Tests
- **End-to-End Conversations**: User input → AI response → Storage
- **Voice Input Flow**: Speech → Text → AI → Response
- **Data Persistence**: Save/Load conversations across app restarts
- **Error Scenarios**: Network failures, permission denials, model errors

### UI Tests
- **Chat Interface**: Message display, scrolling, input handling
- **Settings**: Configuration changes, theme switching
- **Voice Input**: Recording UI, feedback indicators

### Performance Tests
- **Memory Usage**: Monitor during extended conversations
- **Response Times**: Measure AI generation latency
- **Startup Time**: App launch to ready state
- **Database Performance**: Large conversation history handling

## Security Considerations

### Data Protection
- **Local Encryption**: All conversations encrypted at rest using Apple's CryptoKit
- **Keychain Integration**: Secure storage for encryption keys and passcodes
- **Memory Protection**: Clear sensitive data from memory after use
- **No Network Transmission**: All AI processing happens locally

### Privacy
- **No Telemetry**: No usage data collection or transmission
- **Local Logging**: Error logs stored locally only, with user control
- **Permission Management**: Clear requests for microphone access
- **Data Ownership**: User has full control over their data

## Deployment Strategy

### Development Phase
1. **Local Development**: Xcode with SwiftUI previews
2. **Testing**: Unit tests, integration tests, manual testing
3. **Performance Validation**: Memory usage, response times

### Distribution
1. **Development**: Direct .dmg distribution
2. **Beta Testing**: TestFlight for macOS
3. **Production**: Mac App Store submission
4. **Enterprise**: Future .pkg for internal distribution

### iPad Preparation
1. **Shared Business Logic**: Core managers work on both platforms
2. **Platform-Specific UI**: Separate SwiftUI views for iPad
3. **Model Compatibility**: Ensure Mixtral works on iPad hardware
4. **Testing**: iPad-specific testing for touch interactions

## Future Integration Points

### SerenaTools Bridge
```swift
protocol SerenaToolsInterface {
    func executeCommand(_ command: String) async throws -> String
    func listAvailableTools() -> [ToolDescriptor]
    func isToolAvailable(_ toolName: String) -> Bool
}

// Future integration point - not implemented in MVP
class SerenaToolsBridge: SerenaToolsInterface {
    // Will connect to SerenaTools when ready
}
```

### Extension Architecture
- **Plugin System**: Framework for adding new capabilities
- **Tool Integration**: Interface for external tools and services
- **Custom Commands**: Support for user-defined shortcuts and macros

## Performance Targets

### Response Times
- **App Launch**: < 10 seconds to ready state
- **AI Response**: < 5 seconds for typical queries
- **Voice Processing**: < 2 seconds speech-to-text
- **UI Interactions**: < 100ms for all user actions

### Resource Usage
- **Memory**: 2GB typical, 4GB maximum
- **Storage**: < 100MB app size, user data scales with usage
- **CPU**: Efficient use during AI processing, minimal when idle
- **Battery**: Optimized for laptop usage patterns

### Scalability
- **Conversation History**: Support 1000+ conversations
- **Message Volume**: Handle 10,000+ messages per conversation
- **Concurrent Operations**: Voice input while AI processing
- **Background Processing**: Minimal impact when app is backgrounded

## Implementation Phases

### Phase 1: Core Foundation (Week 1-2)
- Basic SwiftUI interface
- ChatManager with simple text conversations
- Local data storage (SQLite)
- Basic error handling

### Phase 2: AI Integration (Week 3-4)
- Mixtral MoE integration
- Context management
- Performance optimization
- Memory management

### Phase 3: Voice and Polish (Week 5-6)
- Voice input implementation
- Settings and configuration
- UI polish and animations
- Comprehensive testing

### Phase 4: Deployment Preparation (Week 7-8)
- App Store compliance review
- Performance validation
- Security audit
- Documentation and distribution

This design provides a solid foundation for the MVP while maintaining clear paths for future enhancement and SerenaTools integration.