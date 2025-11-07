import Foundation

/// Helper service for integrating memory with ChatManager
/// This provides simple methods that can be called from ChatManager without
/// needing to access private members
@available(macOS 13.0, *)
@MainActor
public class MemoryIntegrationHelper {
    public static let shared = MemoryIntegrationHelper()

    private init() {}

    // MARK: - Initialization

    /// Initialize all memory services with user context
    public func initializeMemoryServices() async {
        print("🧠 MemoryIntegrationHelper: Initializing memory services...")

        do {
            // Initialize conversation memory service
            let memoryService = await ConversationMemoryService.shared
            try await memoryService.initialize()

            // Initialize user context for Mike
            let userContext = UserContext(
                name: "Mike",
                role: "CEO",
                company: "Folk Tech AI",
                facts: [
                    "Mike is the CEO of Folk Tech AI",
                    "Folk Tech AI creates AI-powered applications",
                    "Mike is actively developing SerenaNet",
                    "Mike has $1000 in Claude Code credits to use over 2 weeks",
                    "Mike works on both backend (with Claude Code) and frontend/GUI (with Claude Web)",
                    "SerenaNet uses Mistral-7B for local AI processing",
                    "Mike prefers direct, professional communication"
                ]
            )

            try await memoryService.storeUserContext(userContext)

            print("✅ Memory services initialized successfully")
        } catch {
            print("❌ Failed to initialize memory services: \(error)")
        }
    }

    // MARK: - Message Storage

    /// Store a message in memory after it's been added to a conversation
    public func storeMessage(_ message: Message, conversationId: UUID) async {
        do {
            let memoryService = await ConversationMemoryService.shared
            try await memoryService.storeMessage(message, conversationId: conversationId)
        } catch {
            print("⚠️ Failed to store message in memory: \(error)")
            // Don't throw - memory storage is non-critical
        }
    }

    /// Store multiple messages from a conversation
    public func storeConversation(_ conversation: Conversation) async {
        do {
            let memoryService = await ConversationMemoryService.shared
            try await memoryService.storeConversation(conversation)
            print("✅ Conversation stored in memory: \(conversation.messages.count) messages")
        } catch {
            print("⚠️ Failed to store conversation in memory: \(error)")
        }
    }

    // MARK: - Context Enhancement

    /// Get enhanced context messages with semantic search
    /// This can be called before sending messages to the AI
    public func getEnhancedContextMessages(
        for userMessage: String,
        currentMessages: [Message],
        conversationId: UUID
    ) async -> [Message] {
        do {
            let memoryService = await ConversationMemoryService.shared

            // Get semantically relevant messages from past conversations
            let relevantMessages = try await memoryService.getRelevantContext(
                for: userMessage,
                maxMessages: 3
            )

            // Combine with current messages
            var enhancedMessages = currentMessages
            let currentMessageIds = Set(currentMessages.map { $0.id })

            // Add relevant messages that aren't already in context
            for relevantMessage in relevantMessages {
                if !currentMessageIds.contains(relevantMessage.id) {
                    // Insert at the beginning
                    enhancedMessages.insert(relevantMessage, at: 0)
                }
            }

            print("📊 Enhanced context: \(enhancedMessages.count) total messages (\(relevantMessages.count) from semantic search)")

            return enhancedMessages

        } catch {
            print("⚠️ Failed to get semantic context, using basic context: \(error)")
            return currentMessages
        }
    }

    // MARK: - System Prompt

    /// Get system prompt with user context
    public func getSystemPromptWithContext() async -> String {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.generateSystemPrompt(includeMemory: true)
    }

    // MARK: - Statistics

    /// Get memory statistics
    public func getMemoryStatistics() async -> MemoryStatistics? {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getStatistics()
    }

    // MARK: - User Context

    /// Add a new fact about the user
    public func addUserFact(_ fact: String) async {
        do {
            let memoryService = await ConversationMemoryService.shared
            try await memoryService.addUserFact(fact)
            print("✅ Added user fact: \(fact)")
        } catch {
            print("⚠️ Failed to add user fact: \(error)")
        }
    }

    /// Get current user context
    public func getUserContext() async -> UserContext? {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getUserContext()
    }

    // MARK: - Cleanup

    /// Clean up old memory
    public func cleanupMemory(olderThan days: Int = 30) async {
        let memoryService = await ConversationMemoryService.shared
        await memoryService.cleanup(olderThan: days)
    }

    // MARK: - Semantic Search

    /// Search conversation history semantically
    public func semanticSearch(query: String, limit: Int = 10) async throws -> [SemanticSearchResult] {
        let memoryService = await ConversationMemoryService.shared
        return try await memoryService.semanticSearch(query: query, limit: limit)
    }

    // MARK: - All Conversations Access (for Serena)

    /// Search across ALL conversations (not just current one)
    public func searchAllConversations(query: String, limit: Int = 20) async throws -> [ConversationSearchResult] {
        let memoryService = await ConversationMemoryService.shared
        return try await memoryService.searchAllConversations(query: query, limit: limit)
    }

    /// Get all conversation IDs that Serena has access to
    public func getAllConversationIds() async -> [UUID] {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getAllConversationIds()
    }

    /// Get summaries of all conversations
    public func getAllConversationsSummary() async -> [ConversationSummary] {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getAllConversationsSummary()
    }

    /// Get full conversation history for a specific conversation
    public func getConversationHistory(conversationId: UUID) async -> [Message] {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getConversationHistory(conversationId: conversationId)
    }

    // MARK: - Tier Management

    /// Get current user tier (free or paid)
    public func getCurrentTier() async -> UserTier {
        let memoryService = await ConversationMemoryService.shared
        return await memoryService.getCurrentTier()
    }

    /// Update user tier (e.g., when user upgrades to paid)
    public func upgradeToPaid() async {
        let memoryService = await ConversationMemoryService.shared
        await memoryService.updateTier(to: .paid)
        print("✅ User upgraded to paid tier - unlimited memory!")
    }

    /// Downgrade to free tier
    public func downgradeToFree() async {
        let memoryService = await ConversationMemoryService.shared
        await memoryService.updateTier(to: .free)
        print("⬇️ User downgraded to free tier - 30-day retention enforced")

        // Immediately cleanup old messages
        await cleanupMemory()
    }

    /// Get tier configuration with retention info
    public func getTierInfo() async -> String {
        let memoryService = await ConversationMemoryService.shared
        let tier = await memoryService.getCurrentTier()

        switch tier {
        case .free:
            return "Free Tier: 30-day conversation memory, up to 1,000 messages"
        case .paid:
            return "Paid Tier: Unlimited conversation memory, up to 10,000 messages"
        }
    }
}
