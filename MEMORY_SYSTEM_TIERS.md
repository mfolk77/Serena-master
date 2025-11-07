# SerenaNet Memory System - Tier Management & All Conversations Access

**Updated:** 2025-11-07
**Status:** ✅ Complete and Built Successfully

---

## 🆕 What's New

### 1. **Tier-Based Memory Retention**
- **Free Tier:** 30-day conversation memory (1,000 messages max)
- **Paid Tier:** Unlimited conversation memory (10,000 messages max)

### 2. **Serena Can Access ALL Conversations**
- Search across all past conversations, not just current one
- Get summaries of all conversations
- Access full conversation history by ID

---

## 📊 Tier Comparison

| Feature | Free Tier | Paid Tier |
|---------|-----------|-----------|
| **Memory Retention** | 30 days | Unlimited (10 years) |
| **Max Messages** | 1,000 | 10,000 |
| **Semantic Search** | Within 30 days | All time |
| **Conversation Access** | All conversations | All conversations |
| **Storage** | Auto-cleanup daily | Long-term archive |

---

## 🔧 Tier Management API

### Check Current Tier

```swift
let tier = await MemoryIntegrationHelper.shared.getCurrentTier()
print("Current tier: \(tier.displayName)")

// Get tier info string
let info = await MemoryIntegrationHelper.shared.getTierInfo()
// "Free Tier: 30-day conversation memory, up to 1,000 messages"
```

### Upgrade to Paid

```swift
await MemoryIntegrationHelper.shared.upgradeToPaid()
// ✅ User upgraded to paid tier - unlimited memory!
```

### Downgrade to Free

```swift
await MemoryIntegrationHelper.shared.downgradeToFree()
// ⬇️ User downgraded to free tier - 30-day retention enforced
// Auto-cleanup runs immediately
```

---

## 🔍 All Conversations Access (for Serena)

### Search ALL Conversations

```swift
// Search across all conversations the user has ever had
let results = try await MemoryIntegrationHelper.shared.searchAllConversations(
    query: "tool calling system",
    limit: 20
)

for result in results {
    print("Conversation: \(result.conversationId)")
    print("Message: \(result.message.content)")
    print("Similarity: \(result.similarity)")
    print("---")
}
```

**Output example:**
```
Conversation: UUID-1234
Message: We discussed implementing tool calling with TOOL: format...
Similarity: 0.89
---
Conversation: UUID-5678
Message: The tool calling parser needs to handle multiple tools...
Similarity: 0.82
---
```

### Get All Conversation IDs

```swift
let conversationIds = await MemoryIntegrationHelper.shared.getAllConversationIds()
// Returns: [UUID] sorted by most recent

print("Serena has access to \(conversationIds.count) conversations")
```

### Get Conversation Summaries

```swift
let summaries = await MemoryIntegrationHelper.shared.getAllConversationsSummary()

for summary in summaries {
    print("Conversation: \(summary.conversationId)")
    print("Messages: \(summary.messageCount)")
    print("Date Range: \(summary.firstMessageDate) to \(summary.lastMessageDate)")
    print("Preview: \(summary.preview)")
    print("---")
}
```

### Get Full Conversation History

```swift
// Get complete history for a specific conversation
let messages = await MemoryIntegrationHelper.shared.getConversationHistory(
    conversationId: someConversationId
)

print("Conversation has \(messages.count) messages:")
for message in messages {
    print("[\(message.role.displayName)]: \(message.content)")
}
```

---

## 💡 Use Cases for Serena

### 1. Cross-Conversation Context
**User:** "What did we discuss about embeddings?"
**Serena:**
```swift
let results = try await searchAllConversations(query: "embeddings", limit: 5)
// Finds relevant messages from ANY past conversation
// Returns: "In our conversation from Nov 5th, we discussed using 384-dimensional embeddings..."
```

### 2. Conversation Listing
**User:** "Show me all my recent conversations"
**Serena:**
```swift
let summaries = await getAllConversationsSummary()
// Returns list of all conversations with previews
```

### 3. Conversation Resume
**User:** "What were we talking about last Tuesday?"
**Serena:**
```swift
let ids = await getAllConversationIds()
// Filter by date
let messages = await getConversationHistory(conversationId: relevantId)
// Returns: "Last Tuesday we discussed implementing memory tiers..."
```

---

## ⚙️ How Tier Enforcement Works

### Free Tier (Default)

1. **On Initialization:**
   - Checks if auto-cleanup is needed (daily)
   - Removes messages older than 30 days
   - Enforces 1,000 message limit

2. **On New Message:**
   - Stores with embedding
   - If count > 1,000: removes oldest

3. **Auto-Cleanup:**
   - Runs daily automatically
   - Removes messages older than 30 days
   - Preserves user context facts

### Paid Tier

1. **On Upgrade:**
   - Immediately switches to unlimited retention
   - **Does not delete old data** (preserves everything)
   - Updates capacity to 10,000 messages

2. **Retention:**
   - 10-year retention (effectively unlimited)
   - 10x more message storage

3. **No Auto-Cleanup:**
   - Messages kept indefinitely
   - Manual cleanup only if needed

---

## 🗂️ Storage Structure

```
~/Documents/SerenaNet/Memory/
├── conversation_history.json     # All messages
├── embeddings_index.json         # All embeddings
└── tier_config.json              # NEW: Tier configuration
```

**tier_config.json:**
```json
{
    "currentTier": "free",
    "tierStartDate": "2025-11-07T10:30:00Z",
    "lastCleanupDate": "2025-11-07T10:30:00Z"
}
```

---

## 🔒 User Context (Preserved Across Tiers)

User context facts are **NEVER** deleted, even on free tier:
- Mike's name
- Role (CEO)
- Company (Folk Tech AI)
- Custom facts

These are tagged as `type: "user_context"` and excluded from cleanup.

---

## 🚀 Integration Example

### In ChatManager

```swift
// On app launch
Task {
    await MemoryIntegrationHelper.shared.initializeMemoryServices()

    // Check tier
    let tier = await MemoryIntegrationHelper.shared.getCurrentTier()
    print("Memory tier: \(tier.displayName)")
}

// When user asks about past conversations
func handleSerenaQuery(_ query: String) async {
    // Search ALL conversations
    if let results = try? await MemoryIntegrationHelper.shared.searchAllConversations(
        query: query,
        limit: 10
    ) {
        // Build response from results
        var response = "I found these relevant discussions:\n\n"
        for result in results {
            response += "• \(result.snippet) (similarity: \(Int(result.similarity * 100))%)\n"
        }

        return response
    }
}

// When user upgrades
func handleUpgrade() async {
    await MemoryIntegrationHelper.shared.upgradeToPaid()
    // Show success message
}
```

---

## 📈 Statistics with Tier Info

```swift
if let stats = await MemoryIntegrationHelper.shared.getMemoryStatistics() {
    let tier = await MemoryIntegrationHelper.shared.getCurrentTier()

    print("Memory Stats:")
    print("  Tier: \(tier.displayName)")
    print("  Total Messages: \(stats.totalMessages)")
    print("  Total Embeddings: \(stats.totalEmbeddings)")
    print("  Storage: \(stats.storageSizeMB) MB")

    // Show retention info
    switch tier {
    case .free:
        print("  Retention: 30 days (auto-cleanup enabled)")
    case .paid:
        print("  Retention: Unlimited")
    }
}
```

---

## 🔄 Migration from Free to Paid

When a user upgrades:

1. **No Data Loss**
   - All existing messages preserved
   - Even if older than 30 days
   - Embeddings maintained

2. **Immediate Benefits**
   - Retention changes to unlimited
   - Capacity increases to 10,000 messages
   - Auto-cleanup disabled

3. **Example:**
```swift
// User on free tier with 30 days of data
// Upgrades to paid
await upgradeToPaid()

// All 30 days of data KEPT
// New messages stored indefinitely
// Can now store up to 10,000 messages
```

---

## 🎯 Key Features Summary

### ✅ What's Implemented

1. **Tier System**
   - Free tier (30 days, 1,000 messages)
   - Paid tier (unlimited, 10,000 messages)
   - Easy upgrade/downgrade

2. **All Conversations Access**
   - Search across ALL conversations
   - Get conversation summaries
   - Access full conversation history
   - Conversation browsing by ID

3. **Auto-Cleanup**
   - Daily cleanup for free tier
   - Respects tier retention policy
   - Preserves user context

4. **Smart Retention**
   - Tier-based limits
   - Oldest-first removal
   - No data loss on upgrade

---

## 🧪 Testing

### Test Free Tier Retention

```swift
// Set to free tier (default)
let tier = await MemoryIntegrationHelper.shared.getCurrentTier()
assert(tier == .free)

// Store messages
// ... (store 100 messages over 35 days)

// Wait for auto-cleanup (or trigger manually)
await MemoryIntegrationHelper.shared.cleanupMemory()

// Verify: only messages from last 30 days remain
let stats = await MemoryIntegrationHelper.shared.getMemoryStatistics()
// messages older than 30 days should be gone
```

### Test Cross-Conversation Search

```swift
// Store messages in multiple conversations
await storeMessage(message1, conversationId: conv1)
await storeMessage(message2, conversationId: conv2)
await storeMessage(message3, conversationId: conv3)

// Search across all
let results = try await searchAllConversations(query: "test", limit: 10)

// Verify: results from multiple conversations
let uniqueConversations = Set(results.map { $0.conversationId })
assert(uniqueConversations.count >= 2)
```

### Test Tier Upgrade

```swift
// Start on free tier
assert(getCurrentTier() == .free)

// Upgrade
await upgradeToPaid()

// Verify
assert(getCurrentTier() == .paid)

// Verify retention changed
let config = await ConversationMemoryService.shared.getTierConfig()
assert(config.currentTier.memoryRetentionDays > 30)
```

---

## 📝 Summary of Changes

### New Files
- `Sources/SerenaCore/Models/UserTier.swift` - Tier enum & config

### Modified Files
- `ConversationMemoryService.swift` - Tier enforcement, all conversations access
- `MemoryIntegrationHelper.swift` - Tier management API, conversation browsing

### New Methods

**Tier Management:**
- `getCurrentTier() -> UserTier`
- `upgradeToPaid()`
- `downgradeToFree()`
- `getTierInfo() -> String`

**All Conversations:**
- `searchAllConversations(query:limit:) -> [ConversationSearchResult]`
- `getAllConversationIds() -> [UUID]`
- `getAllConversationsSummary() -> [ConversationSummary]`
- `getConversationHistory(conversationId:) -> [Message]`

---

## 🎉 Benefits

1. **Monetization Ready**
   - Clear free vs paid tiers
   - Upgrade path built-in
   - Enforce retention limits

2. **Serena is Smarter**
   - Access to ALL past conversations
   - Cross-conversation context
   - Better long-term memory

3. **User Control**
   - Transparent retention policies
   - Easy tier management
   - No surprise data loss

---

**Build Status:** ✅ Complete (7.93s)
**Ready for:** Production use
**Next:** Integrate tier UI + upgrade flow in GUI

---

End of Tier & All Conversations Documentation
