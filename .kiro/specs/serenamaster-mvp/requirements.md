# SerenaNet MVP - AI Assistant Requirements

**Created:** July 30, 2025 - Wednesday

## Introduction

This specification defines a minimal viable product (MVP) for SerenaNet - a local AI assistant that runs on macOS with plans for iPad deployment. The focus is on core functionality, Apple compliance, and a solid foundation for future expansion.

## Business Context

- **Primary Goal**: Working AI assistant on macOS, ready for iPad
- **Core Value**: Local AI (Mixtral MoE) for privacy and offline capability
- **Constraint**: Apple App Store compliance (avoiding "generic AI chat" rejection)
- **Strategy**: MVP first, then incremental feature additions

## Requirements

### Requirement 1: Core AI Conversation

**User Story:** As a user, I want to have natural conversations with a local AI assistant so that I can get help with tasks while maintaining privacy.

#### Acceptance Criteria

1. WHEN I type a message THEN the AI SHALL respond using local Mixtral MoE
2. WHEN the network is unavailable THEN the AI SHALL continue working offline
3. WHEN I start a new conversation THEN the AI SHALL maintain context within that session
4. WHEN I ask follow-up questions THEN the AI SHALL remember previous context
5. WHEN the AI processes requests THEN response time SHALL be under 5 seconds

### Requirement 2: Clean User Interface

**User Story:** As a user, I want a simple, intuitive interface so that I can focus on my conversations without UI complexity.

#### Acceptance Criteria

1. WHEN I launch the app THEN I SHALL see a clean chat interface
2. WHEN I type messages THEN they SHALL appear clearly formatted
3. WHEN the AI responds THEN responses SHALL be easy to read and distinguish from my messages
4. WHEN I scroll through history THEN the interface SHALL remain responsive
5. WHEN I resize the window THEN the interface SHALL adapt appropriately

### Requirement 3: Local AI Integration

**User Story:** As a user, I want the AI to run locally on my device so that my conversations remain private and work offline.

#### Acceptance Criteria

1. WHEN the app starts THEN it SHALL initialize Mixtral MoE locally
2. WHEN I send a message THEN it SHALL be processed entirely on my device
3. WHEN no internet is available THEN the AI SHALL continue functioning normally
4. WHEN the AI model loads THEN it SHALL complete within 30 seconds on supported hardware
5. WHEN processing messages THEN memory usage SHALL stay under 4GB

### Requirement 4: Voice Input Support

**User Story:** As a user, I want to speak to the assistant so that I can interact hands-free when needed.

#### Acceptance Criteria

1. WHEN I speak to the assistant THEN it SHALL process voice input using local Apple SpeechKit or Whisper fallback
2. WHEN voice input is active THEN I SHALL see clear visual feedback
3. WHEN speech is processed THEN it SHALL appear as text in the conversation
4. WHEN voice recognition fails THEN I SHALL get clear error feedback
5. WHEN using voice input THEN it SHALL work offline with local processing

### Requirement 5: Conversation Persistence

**User Story:** As a user, I want my conversations to be saved so that I can refer back to previous discussions.

#### Acceptance Criteria

1. WHEN I close and reopen the app THEN my recent conversations SHALL be available
2. WHEN I start a new conversation THEN it SHALL be saved automatically
3. WHEN I want to clear history THEN I SHALL have a clear option to do so
4. WHEN conversations are stored THEN they SHALL be encrypted locally
5. WHEN I search conversations THEN I SHALL find relevant messages quickly
6. WHEN the assistant maintains context THEN it SHALL remember up to 10 prior exchanges per session

### Requirement 6: macOS Integration

**User Story:** As a macOS user, I want the app to feel native and integrate well with my system.

#### Acceptance Criteria

1. WHEN I use the app THEN it SHALL follow macOS design guidelines
2. WHEN I use keyboard shortcuts THEN they SHALL work as expected (Cmd+N, Cmd+W, etc.)
3. WHEN I minimize the app THEN it SHALL behave like other macOS apps
4. WHEN I use system features THEN the app SHALL integrate appropriately (notifications, etc.)
5. WHEN I quit the app THEN it SHALL save state and close cleanly

### Requirement 7: Performance and Reliability

**User Story:** As a user, I want the app to be fast and reliable so that it doesn't interfere with my workflow.

#### Acceptance Criteria

1. WHEN the app launches THEN it SHALL start within 10 seconds
2. WHEN I send messages THEN the interface SHALL remain responsive
3. WHEN the AI is processing THEN I SHALL see clear loading indicators
4. WHEN errors occur THEN they SHALL be handled gracefully with clear messages
5. WHEN the app runs for extended periods THEN it SHALL not leak memory or crash
6. WHEN a failure occurs THEN it SHALL be logged using local-only os_log or diagnostic framework

### Requirement 8: iPad Preparation

**User Story:** As a future iPad user, I want the app architecture to support cross-platform deployment.

#### Acceptance Criteria

1. WHEN designing the app THEN the architecture SHALL separate UI from business logic
2. WHEN using platform-specific features THEN they SHALL be properly abstracted
3. WHEN preparing for iPad THEN the core AI functionality SHALL be portable
4. WHEN considering touch interfaces THEN the design SHALL accommodate both mouse and touch
5. WHEN planning deployment THEN the app SHALL meet iOS/iPadOS requirements

### Requirement 9: Apple App Store Compliance

**User Story:** As a product owner, I want the app to meet Apple's standards so that it gets approved for distribution.

#### Acceptance Criteria

1. WHEN submitting for review THEN the app SHALL demonstrate clear value beyond generic chat
2. WHEN using AI features THEN they SHALL be purpose-built and well-integrated
3. WHEN handling user data THEN privacy SHALL be clearly communicated and protected
4. WHEN the app runs THEN it SHALL follow all App Store guidelines
5. WHEN describing the app THEN it SHALL have a clear, specific value proposition

### Requirement 10: Basic Configuration

**User Story:** As a user, I want simple settings so that I can customize the app to my preferences.

#### Acceptance Criteria

1. WHEN I access settings THEN I SHALL find essential options clearly organized
2. WHEN I change themes THEN the interface SHALL update immediately
3. WHEN I adjust AI parameters THEN changes SHALL take effect for new conversations
4. WHEN I modify settings THEN they SHALL persist across app restarts
5. WHEN I reset settings THEN the app SHALL return to sensible defaults
6. WHEN I want privacy THEN the app SHALL support an optional passcode to access saved sessions, toggleable in settings
7. WHEN I use the app THEN it SHALL store a user nickname (e.g. "Mike") to personalize responses and settings

### Requirement 11: Foundation for Growth

**User Story:** As a product owner, I want the MVP to provide a solid foundation for adding features later.

#### Acceptance Criteria

1. WHEN designing the architecture THEN it SHALL support plugin/extension systems
2. WHEN writing code THEN it SHALL be modular and well-documented
3. WHEN planning features THEN the core system SHALL accommodate future additions
4. WHEN considering integrations THEN the architecture SHALL support external connections
5. WHEN building the MVP THEN it SHALL not preclude advanced features from SerenaTools

## Technical Constraints

- **Platform**: macOS 13+ initially, iOS/iPadOS 16+ planned
- **AI Model**: Mixtral MoE (local execution)
- **Language**: Swift with SwiftUI
- **Storage**: Local SQLite database with encryption; support parsing and indexing `.ftai` schema files for structured data access
- **Memory**: Target 2GB typical usage, 4GB maximum
- **Performance**: Sub-5 second response times
- **Voice**: MVP SHALL support on-device voice input using system-native APIs (macOS/iPadOS SpeechKit); fallback: Whisper if available
- **Distribution**: MVP SHALL support distribution via .dmg and TestFlight; future .pkg for enterprise/internal installs

## Success Criteria

- App launches and runs stably on macOS
- Local AI conversations work offline
- Clean, intuitive user interface
- Conversations persist across sessions
- Memory usage stays within targets
- Ready for App Store submission
- Architecture supports iPad deployment
- Foundation ready for SerenaTools integration

## Out of Scope (For MVP)

- Digital estate management
- Business tools and executive features
- Complex authentication systems
- Multi-agent orchestration
- Advanced security features
- Voice output/synthesis (input only for MVP)
- File management
- External API integrations (beyond fallback)

These features remain available in SerenaTools for future integration once the MVP is proven and stable.