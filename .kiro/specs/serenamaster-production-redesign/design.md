# SerenaMaster Production-Ready Redesign Design Document

## Overview

This design document outlines the architecture for transforming SerenaMaster into a production-ready, `.ftai`-driven AI assistant. The core principle is that `.ftai` becomes the central protocol for all communication, memory, input, logging, and orchestration - essentially embedding an operating system inside the agent.

## Architecture

### Core Design Philosophy: .ftai as Operating System Protocol

SerenaMaster will operate as an `.ftai`-native system where:
- All user interactions are converted to `.ftai` format
- All system operations are logged in `.ftai` format
- All memory and context is stored as `.ftai` structures
- All agent decisions are recorded in `.ftai` format
- All configuration and system specs are `.ftai` files

### System Architecture Layers

```
┌─────────────────────────────────────────────────────────────┐
│                    .ftai Protocol Layer                     │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ .ftai Parser    │ │ .ftai Logger    │ │ .ftai Memory    ││
│  │ Engine          │ │ System          │ │ Manager         ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   User Interface Layer                      │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Voice Interface │ │ CLI Interface   │ │ Future: Web UI  ││
│  │ (.ftai driven)  │ │ (.ftai driven)  │ │ (.ftai driven)  ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                 Core Orchestration Layer                    │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ .ftai-driven    │ │ .ftai-driven    │ │ .ftai-driven    ││
│  │ Task Router     │ │ Agent Executor  │ │ Memory System   ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   AI Integration Layer                      │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Local Models    │ │ External APIs   │ │ MCP Agents      ││
│  │ (Mixtral+MLX)   │ │ (OpenAI,Claude) │ │ (.ftai routing) ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
┌─────────────────────────────────────────────────────────────┐
│                   Data Persistence Layer                    │
│  ┌─────────────────┐ ┌─────────────────┐ ┌─────────────────┐│
│  │ Production DB   │ │ .ftai Archives  │ │ Vector Store    ││
│  │ (SQLite/DuckDB) │ │ (Structured)    │ │ (Future)        ││
│  └─────────────────┘ └─────────────────┘ └─────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. .ftai Runtime Engine

The core component that makes SerenaMaster `.ftai`-native:

```swift
public class FTAIRuntimeEngine {
    // Core .ftai processing
    func parseAndExecute(_ ftaiContent: String) async throws -> FTAIExecutionResult
    func convertToFTAI(_ input: Any, context: FTAIContext) -> String
    func logToFTAI(_ event: SystemEvent) async
    
    // Batch processing
    func processBatch(_ ftaiFiles: [String]) async throws -> [FTAIExecutionResult]
    func linkMemoryThreads(_ results: [FTAIExecutionResult]) async
    
    // System integration
    func loadSystemSpecs() async throws
    func validateFTAIIntegrity() async -> ValidationResult
}
```

### 2. Enhanced .ftai Parser with Runtime Support

Extends the existing FTAIParser to support runtime operations:

```swift
public class FTAIParser: FTAIParserProtocol {
    // Existing functionality enhanced
    func parse(ftaiContent: String) async throws -> FTAITask
    
    // New runtime capabilities
    func parseSystemSpec(_ specContent: String) async throws -> FTAISystemSpec
    func parseMemoryThread(_ threadContent: String) async throws -> FTAIMemoryThread
    func parseCommandDefinition(_ cmdContent: String) async throws -> FTAICommand
    
    // Real-time conversion
    func voiceToFTAI(_ audioInput: Data) async throws -> String
    func cliToFTAI(_ cliArgs: [String]) async throws -> String
    func errorToFTAI(_ error: Error, context: ErrorContext) -> String
}
```

### 3. .ftai Specification Files

#### serenamaster.system.ftai
```ftai
System: SerenaMaster Production Architecture
Version: 2.0.0
Protocol: ftai-native

Components:
- FTAIRuntimeEngine: Core protocol processor
- OrchestrationCoordinator: Task coordination with .ftai logging
- AgentRouter: Intelligent routing with .ftai decision trees
- MCPExecutor: Execution with .ftai progress tracking
- MemoryManager: .ftai-structured memory persistence

Capabilities:
- voice.process: Convert speech to .ftai commands
- file.operations: All file ops logged in .ftai format
- memory.management: .ftai-structured context preservation
- agent.routing: .ftai-driven decision making
- error.recovery: .ftai-logged error handling and recovery

Integration:
- Local Models: Mixtral 8x7B via MLX with .ftai I/O
- External APIs: OpenAI, Anthropic with .ftai request/response logging
- Database: Production DB with .ftai archive storage
```

#### serenamaster.commands.ftai
```ftai
Commands: SerenaMaster CLI and Voice Interface
Protocol: ftai-native

Voice Commands:
- "Hey Serena, [command]": Wake word activation with .ftai conversion
- "Process this document": File analysis with .ftai logging
- "Remember this for later": Memory storage in .ftai format
- "What did I work on yesterday": Memory retrieval via .ftai queries

CLI Commands:
- serena --ftai [file]: Direct .ftai file execution
- serena --voice: Voice mode with .ftai conversion
- serena --memory [query]: Memory search via .ftai
- serena --status: System status in .ftai format

Batch Operations:
- serena --batch [directory]: Process all .ftai files in directory
- serena --import [files]: Import and convert to .ftai format
- serena --export [format]: Export .ftai archives
```

#### serenamaster.memory.ftai
```ftai
Memory: SerenaMaster Memory Architecture
Protocol: ftai-native

Structure:
- Short-term: Active .ftai threads and contexts
- Long-term: Archived .ftai conversations and decisions
- File-based: .ftai-linked file associations and metadata
- Context: .ftai thread linking for related operations

Persistence:
- Format: All memory stored as structured .ftai
- Threading: .ftai threads link related operations
- Indexing: .ftai content indexed for fast retrieval
- Backup: .ftai archives with integrity checking

Operations:
- Store: Convert all operations to .ftai before storage
- Retrieve: Query .ftai archives with context awareness
- Link: Connect .ftai threads across time and operations
- Clean: Archive old .ftai threads while preserving links
```

### 4. Production Database Integration

#### Database Selection Criteria:
- **SQLite**: For single-user, embedded scenarios
- **DuckDB**: For analytical workloads and complex queries
- **PostgreSQL**: For multi-user, networked scenarios (future)

#### Schema Design:
```sql
-- .ftai Archives Table
CREATE TABLE ftai_archives (
    id UUID PRIMARY KEY,
    content TEXT NOT NULL,
    thread_id UUID,
    timestamp TIMESTAMP DEFAULT NOW(),
    operation_type VARCHAR(50),
    agent_name VARCHAR(100),
    success BOOLEAN,
    metadata JSONB
);

-- Memory Threads Table
CREATE TABLE memory_threads (
    id UUID PRIMARY KEY,
    name VARCHAR(200),
    created_at TIMESTAMP DEFAULT NOW(),
    last_accessed TIMESTAMP,
    thread_type VARCHAR(50),
    context_data JSONB
);

-- File Associations Table
CREATE TABLE file_associations (
    id UUID PRIMARY KEY,
    file_path TEXT NOT NULL,
    ftai_thread_id UUID REFERENCES memory_threads(id),
    operation_type VARCHAR(50),
    timestamp TIMESTAMP DEFAULT NOW(),
    metadata JSONB
);
```

### 5. Real-time Performance Architecture

#### Performance Requirements:
- Voice command processing: <500ms
- File operations: Real-time feedback
- Memory operations: <100ms for retrieval
- Mode transitions: Seamless, <200ms

#### Optimization Strategies:
```swift
public class PerformanceOptimizer {
    // Pre-compiled .ftai templates for common operations
    private var ftaiTemplateCache: [String: FTAITemplate] = [:]
    
    // Async processing pipeline
    func processAsync(_ ftaiContent: String) async -> FTAIResult
    
    // Memory-efficient .ftai parsing
    func parseStreaming(_ ftaiStream: AsyncSequence<String>) async throws
    
    // Predictive caching
    func preloadLikelyOperations() async
}
```

## Data Models

### Enhanced .ftai Data Models

```swift
// Core .ftai execution result
public struct FTAIExecutionResult {
    let id: UUID
    let originalFTAI: String
    let processedAt: Date
    let success: Bool
    let output: Any?
    let agentDecisions: [FTAIAgentDecision]
    let memoryThreads: [UUID]
    let performanceMetrics: FTAIPerformanceMetrics
}

// .ftai agent decision logging
public struct FTAIAgentDecision {
    let timestamp: Date
    let agentName: String
    let decision: String
    let reasoning: String
    let confidence: Double
    let alternatives: [String]
}

// .ftai system specification
public struct FTAISystemSpec {
    let name: String
    let version: String
    let components: [FTAIComponent]
    let capabilities: [FTAICapability]
    let integrations: [FTAIIntegration]
}

// .ftai memory thread
public struct FTAIMemoryThread {
    let id: UUID
    let name: String
    let ftaiEntries: [String]
    let linkedFiles: [String]
    let contextData: [String: Any]
    let createdAt: Date
    let lastAccessed: Date
}
```

## Error Handling

### .ftai-Native Error Handling

All errors are converted to `.ftai` format for consistent logging and recovery:

```swift
public class FTAIErrorHandler {
    func handleError(_ error: Error, context: ErrorContext) async -> FTAIErrorResponse {
        let ftaiError = convertErrorToFTAI(error, context: context)
        await logFTAIError(ftaiError)
        return generateFTAIRecovery(ftaiError)
    }
    
    private func convertErrorToFTAI(_ error: Error, context: ErrorContext) -> String {
        return """
        Error: \(type(of: error))
        Context: \(context.operation)
        Component: \(context.component)
        Timestamp: \(Date())
        
        Details: \(error.localizedDescription)
        
        Recovery:
        - Fallback: \(suggestFallback(error))
        - Retry: \(shouldRetry(error))
        - User Action: \(suggestUserAction(error))
        """
    }
}
```

## Testing Strategy

### .ftai-Driven Testing

All tests validate `.ftai` integration:

```swift
class FTAIIntegrationTests: XCTestCase {
    func testVoiceToFTAIConversion() async throws {
        let voiceInput = "Hey Serena, process this document"
        let ftaiOutput = try await ftaiEngine.voiceToFTAI(voiceInput)
        
        XCTAssertTrue(ftaiOutput.contains("Task: Process document"))
        XCTAssertTrue(ftaiOutput.contains("Agent: document_processor"))
    }
    
    func testFTAIMemoryThreading() async throws {
        let ftaiCommands = [
            "Task: Create file test.txt",
            "Task: Edit file test.txt",
            "Task: Search in file test.txt"
        ]
        
        let results = try await ftaiEngine.processBatch(ftaiCommands)
        let threadId = try await memoryManager.linkFTAIThread(results)
        
        XCTAssertNotNil(threadId)
        let thread = try await memoryManager.getFTAIThread(threadId)
        XCTAssertEqual(thread.ftaiEntries.count, 3)
    }
}
```

## Implementation Considerations

### 1. Migration Strategy
- Existing JSON data → .ftai format conversion
- Gradual rollout of .ftai-native components
- Backward compatibility during transition

### 2. Performance Optimization
- .ftai template caching for common operations
- Streaming .ftai parsing for large files
- Predictive .ftai operation loading

### 3. Security
- .ftai content validation and sanitization
- Encrypted .ftai archives for sensitive data
- Audit trails in .ftai format

### 4. Extensibility
- Plugin system using .ftai specifications
- Custom .ftai command definitions
- Third-party .ftai integrations

This design transforms SerenaMaster into a true `.ftai`-native system where the protocol becomes the operating system for AI assistance, providing unprecedented consistency, auditability, and extensibility.