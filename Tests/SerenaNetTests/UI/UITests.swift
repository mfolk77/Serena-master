import XCTest
import SwiftUI
@testable import SerenaNet

@MainActor
final class UITests: XCTestCase {
    
    // MARK: - Chat Interface Tests
    
    func testChatViewBasicInteraction() async throws {
        // Test basic chat view functionality
        let chatManager = ChatManager()
        
        // Create a test conversation
        chatManager.createNewConversation()
        
        // Simulate adding messages
        let userMessage = Message(content: "Hello", role: .user)
        let assistantMessage = Message(content: "Hi there!", role: .assistant)
        
        await chatManager.addMessage(userMessage)
        await chatManager.addMessage(assistantMessage)
        
        // Verify messages are in the conversation
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 2)
        XCTAssertEqual(chatManager.currentConversation?.messages[0].content, "Hello")
        XCTAssertEqual(chatManager.currentConversation?.messages[1].content, "Hi there!")
    }
    
    func testMessageInputValidation() async throws {
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Test empty message handling
        await chatManager.sendMessage("")
        XCTAssertEqual(chatManager.lastError, .emptyMessage)
        
        // Test whitespace-only message
        await chatManager.sendMessage("   \n\t   ")
        XCTAssertEqual(chatManager.lastError, .emptyMessage)
        
        // Test valid message
        await chatManager.sendMessage("Valid message")
        XCTAssertNil(chatManager.lastError)
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 2) // User + AI response
    }
    
    func testConversationScrolling() async throws {
        // Test that long conversations can be scrolled through
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Add many messages to test scrolling
        for i in 1...50 {
            let message = Message(content: "Message \(i)", role: i % 2 == 0 ? .user : .assistant)
            await chatManager.addMessage(message)
        }
        
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 50)
        
        // Verify messages are in correct order
        XCTAssertEqual(chatManager.currentConversation?.messages.first?.content, "Message 1")
        XCTAssertEqual(chatManager.currentConversation?.messages.last?.content, "Message 50")
    }
    
    // MARK: - Settings Interface Tests
    
    func testSettingsConfiguration() async throws {
        let configManager = ConfigManager()
        
        // Test initial configuration
        XCTAssertEqual(configManager.userConfig.nickname, "User")
        XCTAssertEqual(configManager.userConfig.theme, .system)
        XCTAssertTrue(configManager.userConfig.voiceInputEnabled)
        
        // Test configuration changes
        configManager.userConfig.nickname = "TestUser"
        configManager.userConfig.theme = .dark
        configManager.userConfig.voiceInputEnabled = false
        
        // Save and reload
        await configManager.saveConfiguration()
        await configManager.loadConfiguration()
        
        // Verify changes persisted
        XCTAssertEqual(configManager.userConfig.nickname, "TestUser")
        XCTAssertEqual(configManager.userConfig.theme, .dark)
        XCTAssertFalse(configManager.userConfig.voiceInputEnabled)
    }
    
    func testAIParameterAdjustment() async throws {
        let configManager = ConfigManager()
        
        // Test AI parameter bounds
        configManager.userConfig.aiParameters.temperature = -1.0
        XCTAssertGreaterThanOrEqual(configManager.userConfig.aiParameters.temperature, 0.0)
        
        configManager.userConfig.aiParameters.temperature = 3.0
        XCTAssertLessThanOrEqual(configManager.userConfig.aiParameters.temperature, 2.0)
        
        // Test valid range
        configManager.userConfig.aiParameters.temperature = 0.7
        configManager.userConfig.aiParameters.maxTokens = 1500
        
        XCTAssertEqual(configManager.userConfig.aiParameters.temperature, 0.7)
        XCTAssertEqual(configManager.userConfig.aiParameters.maxTokens, 1500)
    }
    
    // MARK: - Voice Input Interface Tests
    
    func testVoiceInputUI() async throws {
        let voiceManager = VoiceManager()
        
        // Test initial state
        XCTAssertFalse(voiceManager.isRecording)
        XCTAssertEqual(voiceManager.transcription, "")
        XCTAssertFalse(voiceManager.isProcessing)
        
        // Test permission status
        XCTAssertEqual(voiceManager.permissionStatus, .notDetermined)
        
        // Test audio level monitoring
        XCTAssertEqual(voiceManager.audioLevel, 0.0)
    }
    
    func testVoiceInputStates() async throws {
        let voiceManager = VoiceManager()
        
        // Mock permission granted
        // Note: In real UI tests, this would involve system permission dialogs
        
        // Test recording state changes
        XCTAssertFalse(voiceManager.isRecording)
        
        // Simulate starting recording
        // In actual implementation, this would start the recording process
        // For UI testing, we verify the state management
        
        // Test processing state
        XCTAssertFalse(voiceManager.isProcessing)
        
        // Test transcription updates
        XCTAssertEqual(voiceManager.transcription, "")
    }
    
    // MARK: - Error Display Tests
    
    func testErrorMessageDisplay() async throws {
        let errorManager = ErrorManager()
        
        // Test different error types and their user-friendly messages
        let errors: [SerenaError] = [
            .aiModelNotLoaded,
            .voicePermissionDenied,
            .databaseError("Test error"),
            .networkUnavailable,
            .emptyMessage
        ]
        
        for error in errors {
            let action = errorManager.handle(error, context: "UI Test")
            
            // Verify error has user-friendly description
            XCTAssertFalse(error.localizedDescription.isEmpty)
            XCTAssertNotNil(action)
            
            // Verify error description is user-friendly (not technical)
            let description = error.localizedDescription
            XCTAssertFalse(description.contains("nil"))
            XCTAssertFalse(description.contains("null"))
            XCTAssertFalse(description.contains("exception"))
        }
    }
    
    func testLoadingStateDisplay() async throws {
        let chatManager = ChatManager()
        
        // Test initial processing state
        XCTAssertFalse(chatManager.isProcessing)
        
        // Create conversation
        chatManager.createNewConversation()
        
        // Send message and check processing state
        // Note: In real implementation, we'd need to test the UI shows loading indicators
        await chatManager.sendMessage("Test message")
        
        // After processing, should return to false
        XCTAssertFalse(chatManager.isProcessing)
    }
    
    // MARK: - Navigation Tests
    
    func testConversationNavigation() async throws {
        let chatManager = ChatManager()
        
        // Create multiple conversations
        chatManager.createNewConversation()
        let firstId = chatManager.currentConversation?.id
        await chatManager.sendMessage("First conversation")
        
        chatManager.createNewConversation()
        let secondId = chatManager.currentConversation?.id
        await chatManager.sendMessage("Second conversation")
        
        // Test navigation between conversations
        XCTAssertEqual(chatManager.conversations.count, 2)
        XCTAssertEqual(chatManager.currentConversation?.id, secondId)
        
        // Navigate to first conversation
        guard let firstConversation = chatManager.conversations.first(where: { $0.id == firstId }) else {
            XCTFail("First conversation not found")
            return
        }
        
        chatManager.selectConversation(firstConversation)
        XCTAssertEqual(chatManager.currentConversation?.id, firstId)
        
        // Verify conversation content
        XCTAssertEqual(chatManager.currentConversation?.messages.first?.content, "First conversation")
    }
    
    func testSettingsNavigation() async throws {
        // Test navigation to and from settings
        // This would typically involve testing SwiftUI navigation
        
        let configManager = ConfigManager()
        
        // Test that settings can be accessed and modified
        let originalNickname = configManager.userConfig.nickname
        configManager.userConfig.nickname = "NewNickname"
        
        XCTAssertNotEqual(configManager.userConfig.nickname, originalNickname)
        XCTAssertEqual(configManager.userConfig.nickname, "NewNickname")
    }
    
    // MARK: - Accessibility Tests
    
    func testAccessibilityLabels() async throws {
        // Test that UI elements have proper accessibility labels
        
        // Test message accessibility
        let userMessage = Message(content: "Hello world", role: .user)
        let assistantMessage = Message(content: "Hi there!", role: .assistant)
        
        // Verify messages have identifiable roles for screen readers
        XCTAssertEqual(userMessage.role, .user)
        XCTAssertEqual(assistantMessage.role, .assistant)
        
        // Content should be accessible
        XCTAssertFalse(userMessage.content.isEmpty)
        XCTAssertFalse(assistantMessage.content.isEmpty)
    }
    
    func testKeyboardNavigation() async throws {
        // Test keyboard shortcuts and navigation
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Test that new conversation can be created (Cmd+N equivalent)
        let initialCount = chatManager.conversations.count
        chatManager.createNewConversation()
        XCTAssertEqual(chatManager.conversations.count, initialCount + 1)
        
        // Test message sending (Enter key equivalent)
        await chatManager.sendMessage("Keyboard test message")
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 2)
    }
    
    // MARK: - Theme and Appearance Tests
    
    func testThemeChanges() async throws {
        let configManager = ConfigManager()
        
        // Test theme switching
        let themes: [AppTheme] = [.light, .dark, .system]
        
        for theme in themes {
            configManager.userConfig.theme = theme
            XCTAssertEqual(configManager.userConfig.theme, theme)
            
            // In real UI tests, we'd verify the UI actually changes appearance
            // For now, we just verify the setting is stored correctly
        }
    }
    
    func testResponsiveLayout() async throws {
        // Test that UI adapts to different window sizes
        // This would typically involve testing SwiftUI layout behavior
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Add messages to test layout with content
        for i in 1...10 {
            let message = Message(content: "Test message \(i) with varying lengths of content to test layout responsiveness", role: i % 2 == 0 ? .user : .assistant)
            await chatManager.addMessage(message)
        }
        
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 10)
        
        // Verify messages have content for layout testing
        for message in chatManager.currentConversation?.messages ?? [] {
            XCTAssertFalse(message.content.isEmpty)
        }
    }
    
    // MARK: - Performance UI Tests
    
    func testUIPerformanceWithManyMessages() async throws {
        // Test UI performance with large number of messages
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        let startTime = Date()
        
        // Add many messages
        for i in 1...1000 {
            let message = Message(content: "Performance test message \(i)", role: i % 2 == 0 ? .user : .assistant)
            await chatManager.addMessage(message)
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete within reasonable time (adjust threshold as needed)
        XCTAssertLessThan(duration, 5.0, "Adding 1000 messages took too long: \(duration) seconds")
        
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 1000)
    }
    
    func testMemoryUsageWithLargeConversations() async throws {
        // Test memory usage doesn't grow excessively
        
        let performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.startMonitoring()
        
        let initialMemory = performanceMonitor.currentMemoryUsage
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Create large conversation
        for i in 1...500 {
            await chatManager.sendMessage("Memory test message \(i)")
        }
        
        // Wait for memory monitoring to update
        try await Task.sleep(nanoseconds: 200_000_000) // 0.2 seconds
        
        let finalMemory = performanceMonitor.currentMemoryUsage
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory increase should be reasonable (less than 100MB for 500 messages)
        let maxAllowedIncrease: Int64 = 100 * 1024 * 1024 // 100MB
        XCTAssertLessThan(memoryIncrease, maxAllowedIncrease, "Memory usage increased too much: \(memoryIncrease) bytes")
        
        performanceMonitor.stopMonitoring()
    }
    
    // MARK: - Integration UI Tests
    
    func testCompleteUserWorkflow() async throws {
        // Test a complete user workflow from start to finish
        
        let chatManager = ChatManager()
        let configManager = ConfigManager()
        
        // 1. User opens app and configures settings
        configManager.userConfig.nickname = "TestUser"
        configManager.userConfig.theme = .dark
        await configManager.saveConfiguration()
        
        // 2. User creates new conversation
        chatManager.createNewConversation()
        XCTAssertNotNil(chatManager.currentConversation)
        
        // 3. User sends multiple messages
        let messages = [
            "Hello, I'm new to this app",
            "Can you help me with Swift programming?",
            "What are the best practices for iOS development?"
        ]
        
        for message in messages {
            await chatManager.sendMessage(message)
        }
        
        // 4. Verify conversation has all exchanges
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 6) // 3 user + 3 AI
        
        // 5. User creates second conversation
        chatManager.createNewConversation()
        await chatManager.sendMessage("This is a second conversation")
        
        // 6. Verify multiple conversations exist
        XCTAssertEqual(chatManager.conversations.count, 2)
        
        // 7. User switches between conversations
        let firstConversation = chatManager.conversations[1] // Second in array (first created)
        chatManager.selectConversation(firstConversation)
        
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 6)
        
        // 8. User deletes a conversation
        await chatManager.deleteConversation(firstConversation)
        XCTAssertEqual(chatManager.conversations.count, 1)
        
        // 9. Verify final state
        XCTAssertEqual(chatManager.currentConversation?.messages.count, 2) // Second conversation
    }
}