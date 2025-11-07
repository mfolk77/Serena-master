import Foundation
import SwiftUI

enum ConversationSortType: String, CaseIterable {
    case mostRecent = "Most Recent"
    case oldest = "Oldest"
    case alphabetical = "Alphabetical"
    case messageCount = "Message Count"
}

struct MessageRelevanceScore {
    let message: Message
    let score: Double
}

struct ContextStatistics {
    let totalMessages: Int
    let contextMessages: Int
    let totalExchanges: Int
    let contextExchanges: Int
    let compressionRatio: Double
    
    var isContextTrimmed: Bool {
        return totalMessages > contextMessages
    }
    
    var description: String {
        return "Context: \(contextMessages)/\(totalMessages) messages (\(contextExchanges)/\(totalExchanges) exchanges), compression: \(String(format: "%.2f", compressionRatio))"
    }
}

@MainActor
class ChatManager: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var currentConversation: Conversation?
    @Published var isProcessing: Bool = false
    @Published var lastError: SerenaError?
    
    private let dataStore: DataStoreProtocol
    private let errorManager: ErrorManager
    private let voiceManager: VoiceManager
    private let networkManager: NetworkConnectivityManager
    private let aiEngine: any AIEngine
    private let orchestrator: SerenaOrchestrator
    private let performanceMonitor = PerformanceMonitor.shared
    private let accessibilityManager = AccessibilityManager.shared
    
    // For dependency injection in tests
    init(dataStore: DataStoreProtocol? = nil, errorManager: ErrorManager? = nil, voiceManager: VoiceManager? = nil, networkManager: NetworkConnectivityManager? = nil, aiEngine: (any AIEngine)? = nil, configManager: ConfigManager? = nil) {
        self.errorManager = errorManager ?? ErrorManager()
        self.voiceManager = voiceManager ?? VoiceManager()
        self.networkManager = networkManager ?? NetworkConnectivityManager()
        self.aiEngine = aiEngine ?? MixtralEngine()
        
        let config = configManager ?? ConfigManager()
        self.orchestrator = SerenaOrchestrator(aiEngine: self.aiEngine, configManager: config)
        
        if let dataStore = dataStore {
            self.dataStore = dataStore
        } else {
            do {
                self.dataStore = try DataStore()
            } catch {
                // Create a fallback in-memory store for testing
                self.dataStore = try! DataStore()
                Task { @MainActor in
                    self.errorManager.handle(.databaseError(error.localizedDescription), context: "ChatManager initialization")
                }
            }
        }
        
        // Initialize RTAI system and AI engine
        Task {
            await initializeRTAIAndAI()
        }
    }
    
    // MARK: - AI Engine and RTAI Management
    
    private func initializeRTAIAndAI() async {
        print("🚀 ChatManager: Initializing RTAI and AI systems...")
        
        // First initialize RTAI system
        let rtaiSuccess = RTAIBridge.initializeShared()
        if rtaiSuccess {
            print("✅ ChatManager: RTAI system initialized successfully")
        } else {
            print("⚠️ ChatManager: RTAI initialization failed, using fallback responses")
        }
        
        // Then initialize AI engine
        await initializeAIEngine()
    }
    
    private func initializeAIEngine() async {
        print("🔍 DEBUG: ChatManager.initializeAIEngine() called")
        do {
            print("🔍 DEBUG: About to call aiEngine.initialize()")
            try await aiEngine.initialize()
            print("🔍 DEBUG: aiEngine.initialize() completed successfully")
        } catch {
            print("🔍 DEBUG: aiEngine.initialize() failed with error: \(error)")
            print("💡 ChatManager: AI engine failed, but RTAI can provide responses")
            errorManager.handle(.aiModelInitializationFailed(error.localizedDescription), context: "AI engine initialization")
        }
    }
    
    // MARK: - Network Status
    
    /// Check if the app is currently offline
    var isOffline: Bool {
        return !networkManager.isConnected
    }
    
    /// Get current network status message
    var networkStatusMessage: String {
        return networkManager.getStatusMessage()
    }
    
    /// Get offline mode guidance
    var offlineModeGuidance: String {
        return networkManager.getOfflineModeGuidance()
    }
    
    /// Access to network manager for UI components
    var networkConnectivityManager: NetworkConnectivityManager {
        return networkManager
    }
    
    // MARK: - Conversation Management
    
    func loadConversations() async {
        do {
            conversations = try await dataStore.loadConversations()
            
            // Sort conversations by most recent first
            conversations.sort { $0.updatedAt > $1.updatedAt }
            
            // Set current conversation to the most recent one, or create new if none exist
            if let mostRecent = conversations.first {
                currentConversation = mostRecent
            } else {
                createNewConversation()
            }
            
            lastError = nil
        } catch {
            let serenaError = SerenaError.databaseError(error.localizedDescription)
            lastError = serenaError
            errorManager.handle(serenaError, context: "Loading conversations")
            createNewConversation()
        }
    }
    
    func createNewConversation() {
        let newConversation = Conversation()
        currentConversation = newConversation
        conversations.insert(newConversation, at: 0)
    }
    
    func selectConversation(_ conversation: Conversation) {
        guard conversations.contains(where: { $0.id == conversation.id }) else {
            lastError = SerenaError.conversationNotFound
            return
        }
        currentConversation = conversation
    }
    
    /// Get conversation by ID
    func getConversation(id: UUID) -> Conversation? {
        return conversations.first { $0.id == id }
    }
    
    /// Get the number of conversations
    var conversationCount: Int {
        return conversations.count
    }
    
    /// Check if there are any conversations
    var hasConversations: Bool {
        return !conversations.isEmpty
    }
    
    // MARK: - Search and Filtering
    
    /// Search conversations by title or message content
    func searchConversations(query: String) -> [Conversation] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        guard !trimmedQuery.isEmpty else { return conversations }
        
        return conversations.filter { conversation in
            // Search in title
            if conversation.title.lowercased().contains(trimmedQuery) {
                return true
            }
            
            // Search in message content
            return conversation.messages.contains { message in
                message.content.lowercased().contains(trimmedQuery)
            }
        }
    }
    
    /// Filter conversations by date range
    func filterConversations(from startDate: Date? = nil, to endDate: Date? = nil) -> [Conversation] {
        return conversations.filter { conversation in
            if let startDate = startDate, conversation.createdAt < startDate {
                return false
            }
            if let endDate = endDate, conversation.createdAt > endDate {
                return false
            }
            return true
        }
    }
    
    /// Filter conversations by message count
    func filterConversations(minMessages: Int? = nil, maxMessages: Int? = nil) -> [Conversation] {
        return conversations.filter { conversation in
            let messageCount = conversation.messages.count
            if let minMessages = minMessages, messageCount < minMessages {
                return false
            }
            if let maxMessages = maxMessages, messageCount > maxMessages {
                return false
            }
            return true
        }
    }
    
    /// Get conversations sorted by different criteria
    func getSortedConversations(by sortType: ConversationSortType) -> [Conversation] {
        switch sortType {
        case .mostRecent:
            return conversations.sorted { $0.updatedAt > $1.updatedAt }
        case .oldest:
            return conversations.sorted { $0.updatedAt < $1.updatedAt }
        case .alphabetical:
            return conversations.sorted { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .messageCount:
            return conversations.sorted { $0.messages.count > $1.messages.count }
        }
    }
    
    /// Get recent conversations (last N conversations)
    func getRecentConversations(limit: Int = 10) -> [Conversation] {
        let sortedConversations = conversations.sorted { $0.updatedAt > $1.updatedAt }
        return Array(sortedConversations.prefix(limit))
    }
    
    // MARK: - Context Window Management
    
    /// Maximum number of exchanges to maintain in context (10 exchanges = 20 messages)
    private let maxContextExchanges = 10
    
    /// Get context messages for AI processing with intelligent trimming
    func getContextMessages(for conversation: Conversation) -> [Message] {
        return getContextMessagesWithRelevanceScoring(conversation: conversation)
    }
    
    /// Get context messages with relevance scoring for better retention
    private func getContextMessagesWithRelevanceScoring(conversation: Conversation) -> [Message] {
        let messages = conversation.messages
        let maxMessages = maxContextExchanges * 2 // Each exchange is user + assistant
        
        // If we're within the limit, return all messages
        if messages.count <= maxMessages {
            return messages
        }
        
        // Score messages for relevance
        let scoredMessages = scoreMessagesForRelevance(messages)
        
        // Always keep the most recent messages
        let recentMessages = Array(messages.suffix(maxMessages / 2))
        
        // Select additional messages based on relevance scores
        let remainingSlots = maxMessages - recentMessages.count
        let olderMessages = Array(messages.dropLast(recentMessages.count))
        let selectedOlderMessages = selectTopScoredMessages(scoredMessages, from: olderMessages, count: remainingSlots)
        
        // Combine and sort by timestamp to maintain conversation flow
        let contextMessages = (selectedOlderMessages + recentMessages).sorted { $0.timestamp < $1.timestamp }
        
        return contextMessages
    }
    
    /// Score messages based on relevance criteria
    private func scoreMessagesForRelevance(_ messages: [Message]) -> [MessageRelevanceScore] {
        return messages.map { message in
            var score: Double = 0.0
            
            // Base score for all messages
            score += 1.0
            
            // Higher score for longer messages (more content)
            let contentLength = Double(message.content.count)
            score += min(contentLength / 100.0, 3.0) // Cap at 3 points for length
            
            // Higher score for messages with questions (user engagement)
            if message.content.contains("?") {
                score += 2.0
            }
            
            // Higher score for messages with code or technical terms
            let technicalTerms = ["func", "class", "struct", "import", "let", "var", "if", "for", "while", "return", "error", "exception"]
            let technicalTermCount = technicalTerms.reduce(0) { count, term in
                count + (message.content.lowercased().contains(term) ? 1 : 0)
            }
            score += Double(technicalTermCount) * 0.5
            
            // Higher score for assistant messages that provide explanations
            if message.role == .assistant {
                if message.content.contains("because") || message.content.contains("explanation") || message.content.contains("example") {
                    score += 1.5
                }
            }
            
            // Recency bonus (more recent messages get higher scores)
            let timeSinceMessage = Date().timeIntervalSince(message.timestamp)
            let recencyBonus = max(0, 2.0 - (timeSinceMessage / 3600.0)) // Bonus decreases over hours
            score += recencyBonus
            
            return MessageRelevanceScore(message: message, score: score)
        }
    }
    
    /// Select top scored messages from a collection
    private func selectTopScoredMessages(_ scoredMessages: [MessageRelevanceScore], from messages: [Message], count: Int) -> [Message] {
        let relevantScores = scoredMessages.filter { scoredMessage in
            messages.contains { $0.id == scoredMessage.message.id }
        }
        
        let sortedByScore = relevantScores.sorted { $0.score > $1.score }
        let selectedScores = Array(sortedByScore.prefix(count))
        
        return selectedScores.map { $0.message }
    }
    
    /// Trim conversation context when it exceeds limits
    func trimConversationContext(_ conversation: inout Conversation) {
        let maxTotalMessages = maxContextExchanges * 4 // Allow 2x the context limit before trimming
        
        if conversation.messages.count > maxTotalMessages {
            // Keep the most recent messages and some high-relevance older messages
            let recentMessages = Array(conversation.messages.suffix(maxTotalMessages / 2))
            let olderMessages = selectHighRelevanceMessages(from: conversation.messages, excluding: recentMessages, count: maxTotalMessages / 2)
            let trimmedMessages = recentMessages + olderMessages
            
            conversation.messages = trimmedMessages.sorted { $0.timestamp < $1.timestamp }
        }
    }
    
    /// Select high relevance messages excluding already selected ones
    private func selectHighRelevanceMessages(from messages: [Message], excluding excludedMessages: [Message], count: Int) -> [Message] {
        let excludedIds = Set(excludedMessages.map { $0.id })
        let candidateMessages = messages.filter { !excludedIds.contains($0.id) }
        
        let scoredMessages = scoreMessagesForRelevance(candidateMessages)
        let sortedByScore = scoredMessages.sorted { $0.score > $1.score }
        let selectedScores = Array(sortedByScore.prefix(count))
        
        return selectedScores.map { $0.message }
    }
    
    /// Get context statistics for debugging/monitoring
    func getContextStatistics(for conversation: Conversation) -> ContextStatistics {
        let totalMessages = conversation.messages.count
        let contextMessages = getContextMessages(for: conversation)
        let contextSize = contextMessages.count
        let exchanges = totalMessages / 2
        let contextExchanges = contextSize / 2
        
        return ContextStatistics(
            totalMessages: totalMessages,
            contextMessages: contextSize,
            totalExchanges: exchanges,
            contextExchanges: contextExchanges,
            compressionRatio: totalMessages > 0 ? Double(contextSize) / Double(totalMessages) : 1.0
        )
    }
    
    // MARK: - Voice Input
    
    /// Access to the voice manager for UI components
    var voiceInputManager: VoiceManager {
        return self.voiceManager
    }
    
    /// Start voice input and return transcription when complete
    func startVoiceInput() async throws -> String {
        do {
            // Validate that voice recognition can proceed offline
            try networkManager.validateOfflineOperation(.voiceRecognition)
            
            // Request permissions if needed
            if voiceManager.permissionStatus != .authorized {
                let granted = await voiceManager.requestPermissions()
                if !granted {
                    throw SerenaError.voicePermissionDenied
                }
            }
            
            // Start recording
            try await voiceManager.startRecording()
            
            // Wait for user to stop recording (this would be handled by UI)
            // For now, we'll return empty string as this method is meant to be called by UI
            return ""
        } catch {
            if let serenaError = error as? SerenaError {
                lastError = serenaError
                errorManager.handle(serenaError, context: "Starting voice input")
                throw serenaError
            } else {
                let serenaError = SerenaError.voiceRecognitionFailed(error.localizedDescription)
                lastError = serenaError
                errorManager.handle(serenaError, context: "Starting voice input")
                throw serenaError
            }
        }
    }
    
    /// Stop voice input and process the transcription
    func stopVoiceInput() async throws -> String {
        let transcription = await voiceManager.stopRecording()
        
        if !transcription.isEmpty {
            // Automatically send the transcribed message
            await sendMessage(transcription)
        }
        
        return transcription
    }
    
    /// Send a voice message (transcription + send)
    func sendVoiceMessage() async throws {
        do {
            let transcription = try await stopVoiceInput()
            if transcription.isEmpty {
                throw SerenaError.emptyMessage
            }
        } catch {
            throw error
        }
    }
    
    /// Check if voice input is available
    var isVoiceInputAvailable: Bool {
        return voiceManager.permissionStatus == .authorized
    }
    
    /// Check if currently recording voice
    var isRecordingVoice: Bool {
        return voiceManager.isRecording
    }
    
    // MARK: - Message Handling
    
    func sendMessage(_ text: String) async {
        print("🔄 ChatManager.sendMessage: Starting with text: '\(text)'")
        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedText.isEmpty else { 
            print("❌ ChatManager.sendMessage: Empty message")
            lastError = SerenaError.emptyMessage
            return 
        }
        
        print("🔄 ChatManager.sendMessage: Checking conversation...")
        // Ensure we have a current conversation
        if currentConversation == nil {
            print("🔄 ChatManager.sendMessage: Creating new conversation")
            createNewConversation()
        }
        
        guard var conversation = currentConversation else { 
            print("❌ ChatManager.sendMessage: No conversation available")
            lastError = SerenaError.conversationNotFound
            return 
        }
        
        print("🔄 ChatManager.sendMessage: Conversation found: \(conversation.id)")
        
        do {
            print("🔄 ChatManager.sendMessage: Adding user message...")
            // Add user message
            let userMessage = Message(content: trimmedText, role: .user)
            conversation.addMessage(userMessage)
            currentConversation = conversation
            
            print("🔄 ChatManager.sendMessage: Updating conversation array...")
            // Update conversations array
            updateConversationInArray(conversation)
            
            print("🔄 ChatManager.sendMessage: Saving conversation...")
            // Save conversation
            try await dataStore.saveConversation(conversation)
            
            print("🔄 ChatManager.sendMessage: About to generate AI response...")
            // Generate AI response
            await generateAIResponse()
            
            print("✅ ChatManager.sendMessage: Completed successfully")
            lastError = nil
        } catch {
            print("❌ ChatManager.sendMessage: Error: \(error)")
            let serenaError = SerenaError.databaseError(error.localizedDescription)
            lastError = serenaError
            errorManager.handle(serenaError, context: "Sending message")
        }
    }
    
    /// Add a message to the current conversation without triggering AI response
    func addMessage(_ message: Message) async {
        guard var conversation = currentConversation else {
            createNewConversation()
            guard var conversation = currentConversation else { return }
            conversation.addMessage(message)
            currentConversation = conversation
            updateConversationInArray(conversation)
            await saveCurrentConversation()
            return
        }
        
        conversation.addMessage(message)
        currentConversation = conversation
        updateConversationInArray(conversation)
        await saveCurrentConversation()
    }
    
    /// Get message count for current conversation
    var currentMessageCount: Int {
        return currentConversation?.messages.count ?? 0
    }
    
    /// Get the last message from current conversation
    var lastMessage: Message? {
        return currentConversation?.lastMessage
    }
    
    private func generateAIResponse() async {
        print("🤖 ChatManager.generateAIResponse: Starting...")
        guard var conversation = currentConversation else { 
            print("❌ generateAIResponse: No current conversation")
            return 
        }
        
        print("🤖 generateAIResponse: Setting isProcessing = true")
        isProcessing = true
        
        do {
            // Validate that AI inference can proceed (should always work offline)
            try networkManager.validateOfflineOperation(.aiInference)
            
            // Get context messages for AI processing
            let contextMessages = getContextMessages(for: conversation)
            
            // Get the last user message
            guard let lastUserMessage = conversation.messages.last?.content else {
                throw SerenaError.emptyMessage
            }
            
            print("🤖 generateAIResponse: About to generate response for: '\(lastUserMessage)'")
            
            // Generate AI response using SerenaOrchestrator with performance monitoring
            let responseText = try await performanceMonitor.measureResponseTime {
                print("🤖 generateAIResponse: Calling orchestrator.processInput with context: \(contextMessages.count) messages")
                return try await orchestrator.processInput(lastUserMessage, context: contextMessages)
            }
            
            print("🤖 generateAIResponse: Generated response: '\(responseText)'")
            
            let assistantMessage = Message(content: responseText, role: .assistant)
            
            conversation.addMessage(assistantMessage)
            
            // Trim context if conversation is getting too long
            trimConversationContext(&conversation)
            
            currentConversation = conversation
            
            // Update conversations array
            updateConversationInArray(conversation)
            
            // Save conversation (works offline with local storage)
            try await dataStore.saveConversation(conversation)
            
            // Announce AI response for accessibility
            accessibilityManager.announceAIResponse(responseText)
            
            lastError = nil
        } catch {
            let serenaError: SerenaError
            if let existingError = error as? SerenaError {
                serenaError = existingError
            } else {
                serenaError = SerenaError.aiProcessingError(error.localizedDescription)
            }
            
            lastError = serenaError
            errorManager.handle(serenaError, context: "Generating AI response")
        }
        
        isProcessing = false
    }
    

    
    // MARK: - Data Persistence
    
    private func saveCurrentConversation() async {
        guard let conversation = currentConversation else { return }
        
        do {
            try await dataStore.saveConversation(conversation)
            lastError = nil
        } catch {
            let serenaError = SerenaError.databaseError(error.localizedDescription)
            lastError = serenaError
            errorManager.handle(serenaError, context: "Saving conversation")
        }
    }
    
    func deleteConversation(_ conversation: Conversation) async {
        do {
            try await dataStore.deleteConversation(id: conversation.id)
            conversations.removeAll { $0.id == conversation.id }
            
            if currentConversation?.id == conversation.id {
                currentConversation = conversations.first
                if currentConversation == nil {
                    createNewConversation()
                }
            }
            
            lastError = nil
        } catch {
            let serenaError = SerenaError.databaseError(error.localizedDescription)
            lastError = serenaError
            errorManager.handle(serenaError, context: "Deleting conversation")
        }
    }
    
    func clearAllConversations() async {
        do {
            try await dataStore.clearAllData()
            conversations.removeAll()
            createNewConversation()
            lastError = nil
        } catch {
            let serenaError = SerenaError.databaseError(error.localizedDescription)
            lastError = serenaError
            errorManager.handle(serenaError, context: "Clearing conversations")
        }
    }
    
    // MARK: - Drag and Drop Support
    
    /// Handle dropped text content
    func handleDroppedText(_ text: String) {
        Task {
            await sendMessage(text)
        }
    }
    
    /// Handle dropped file URLs
    func handleDroppedFile(_ url: URL) {
        Task {
            do {
                let content = try String(contentsOf: url, encoding: .utf8)
                let fileName = url.lastPathComponent
                let message = "File: \(fileName)\n\n\(content)"
                await sendMessage(message)
            } catch {
                let errorMessage = "Could not read file: \(url.lastPathComponent)\nError: \(error.localizedDescription)"
                await sendMessage(errorMessage)
            }
        }
    }
    
    // MARK: - Menu Support
    
    /// Clear the current conversation
    func clearCurrentConversation() {
        guard var conversation = currentConversation else { return }
        conversation.messages.removeAll()
        currentConversation = conversation
        updateConversationInArray(conversation)
        
        Task {
            await saveCurrentConversation()
        }
    }
    
    /// Delete the current conversation
    func deleteCurrentConversation() {
        guard let conversation = currentConversation else { return }
        Task {
            await deleteConversation(conversation)
        }
    }
    
    /// Copy the last assistant response to clipboard
    func copyLastResponse() {
        guard let conversation = currentConversation else { return }
        
        // Find the last assistant message
        let lastAssistantMessage = conversation.messages.reversed().first { $0.role == .assistant }
        
        if let message = lastAssistantMessage {
            let pasteboard = NSPasteboard.general
            pasteboard.clearContents()
            pasteboard.setString(message.content, forType: .string)
        }
    }
    
    /// Check if we can copy the last response
    var canCopyLastResponse: Bool {
        guard let conversation = currentConversation else { return false }
        return conversation.messages.contains { $0.role == .assistant }
    }
    
    /// Start voice input (for menu command)
    func startVoiceInput() {
        Task {
            do {
                accessibilityManager.announceVoiceInputStart()
                _ = try await startVoiceInput()
            } catch {
                // Error handling is already done in the async method
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func updateConversationInArray(_ conversation: Conversation) {
        if let index = conversations.firstIndex(where: { $0.id == conversation.id }) {
            conversations[index] = conversation
            // Move to front if it's not already there
            if index != 0 {
                conversations.remove(at: index)
                conversations.insert(conversation, at: 0)
            }
        } else {
            // Add new conversation to the front
            conversations.insert(conversation, at: 0)
        }
    }
}