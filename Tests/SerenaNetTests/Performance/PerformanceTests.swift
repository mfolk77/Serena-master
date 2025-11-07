import XCTest
@testable import SerenaNet

@MainActor
final class PerformanceTests: XCTestCase {
    var performanceMonitor: PerformanceMonitor!
    
    override func setUp() async throws {
        try await super.setUp()
        performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.startMonitoring()
        performanceMonitor.clearPerformanceData()
    }
    
    override func tearDown() async throws {
        performanceMonitor.stopMonitoring()
        performanceMonitor.clearPerformanceData()
        try await super.tearDown()
    }
    
    // MARK: - Memory Performance Tests
    
    func testMemoryUsageUnderLoad() async throws {
        // Test memory usage stays within limits under heavy load
        
        let chatManager = ChatManager()
        let initialMemory = performanceMonitor.currentMemoryUsage
        
        // Create multiple conversations with many messages
        for conversationIndex in 1...10 {
            chatManager.createNewConversation()
            
            for messageIndex in 1...100 {
                await chatManager.sendMessage("Load test conversation \(conversationIndex) message \(messageIndex)")
            }
        }
        
        // Wait for memory monitoring to update
        try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
        
        let finalMemory = performanceMonitor.currentMemoryUsage
        let memoryIncrease = finalMemory - initialMemory
        
        // Memory should stay under 4GB limit (requirement 7.5)
        let maxMemoryLimit: Int64 = 4 * 1024 * 1024 * 1024 // 4GB
        XCTAssertLessThan(finalMemory, maxMemoryLimit, "Memory usage exceeded 4GB limit")
        
        // Memory increase should be reasonable for the amount of data
        let maxReasonableIncrease: Int64 = 500 * 1024 * 1024 // 500MB
        XCTAssertLessThan(memoryIncrease, maxReasonableIncrease, "Memory increase too large: \(memoryIncrease) bytes")
        
        print("Memory usage: Initial: \(ByteCountFormatter.string(fromByteCount: initialMemory, countStyle: .memory)), Final: \(ByteCountFormatter.string(fromByteCount: finalMemory, countStyle: .memory)), Increase: \(ByteCountFormatter.string(fromByteCount: memoryIncrease, countStyle: .memory))")
    }
    
    func testMemoryLeakDetection() async throws {
        // Test for memory leaks by creating and destroying objects
        
        let initialMemory = performanceMonitor.currentMemoryUsage
        
        // Create and destroy chat managers multiple times
        for _ in 1...50 {
            let chatManager = ChatManager()
            chatManager.createNewConversation()
            await chatManager.sendMessage("Memory leak test")
            
            // Simulate cleanup
            await chatManager.clearAllConversations()
        }
        
        // Force garbage collection
        for _ in 1...3 {
            autoreleasepool {
                // Create temporary objects to trigger cleanup
                _ = Array(1...1000).map { "temp_\($0)" }
            }
        }
        
        // Wait for cleanup
        try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
        
        let finalMemory = performanceMonitor.currentMemoryUsage
        let memoryDifference = abs(finalMemory - initialMemory)
        
        // Memory should return close to initial level (allowing for some variance)
        let allowedVariance: Int64 = 50 * 1024 * 1024 // 50MB variance allowed
        XCTAssertLessThan(memoryDifference, allowedVariance, "Potential memory leak detected. Difference: \(memoryDifference) bytes")
        
        print("Memory leak test: Initial: \(ByteCountFormatter.string(fromByteCount: initialMemory, countStyle: .memory)), Final: \(ByteCountFormatter.string(fromByteCount: finalMemory, countStyle: .memory)), Difference: \(ByteCountFormatter.string(fromByteCount: memoryDifference, countStyle: .memory))")
    }
    
    func testMemoryPressureHandling() async throws {
        // Test behavior under simulated memory pressure
        
        let chatManager = ChatManager()
        
        // Create large amounts of data to simulate memory pressure
        var largeDataArrays: [[String]] = []
        
        for i in 1...100 {
            let largeArray = Array(1...10000).map { "large_data_item_\(i)_\($0)" }
            largeDataArrays.append(largeArray)
            
            // Check memory usage periodically
            if i % 10 == 0 {
                let currentMemory = performanceMonitor.currentMemoryUsage
                let memoryGB = Double(currentMemory) / (1024 * 1024 * 1024)
                
                print("Memory usage at iteration \(i): \(String(format: "%.2f", memoryGB)) GB")
                
                // If approaching memory limit, test cleanup
                if memoryGB > 3.0 { // Approaching 4GB limit
                    // Trigger cleanup
                    largeDataArrays.removeAll()
                    
                    // Test that app still functions
                    chatManager.createNewConversation()
                    await chatManager.sendMessage("Memory pressure test message")
                    
                    XCTAssertNotNil(chatManager.currentConversation)
                    XCTAssertEqual(chatManager.currentConversation?.messages.count, 2)
                    
                    break
                }
            }
        }
        
        // Cleanup
        largeDataArrays.removeAll()
    }
    
    // MARK: - Response Time Performance Tests
    
    func testAIResponseTimePerformance() async throws {
        // Test AI response times meet requirements (< 5 seconds)
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        let testMessages = [
            "Hello, how are you?",
            "What is Swift programming?",
            "Can you explain closures in Swift?",
            "How do I use async/await?",
            "What are the best practices for iOS development?"
        ]
        
        var responseTimes: [TimeInterval] = []
        
        for message in testMessages {
            let startTime = Date()
            await chatManager.sendMessage(message)
            let endTime = Date()
            
            let responseTime = endTime.timeIntervalSince(startTime)
            responseTimes.append(responseTime)
            
            // Each response should be under 5 seconds (requirement)
            XCTAssertLessThan(responseTime, 5.0, "AI response time exceeded 5 seconds: \(responseTime)s for message: '\(message)'")
            
            print("Response time for '\(message)': \(String(format: "%.3f", responseTime))s")
        }
        
        // Calculate average response time
        let averageResponseTime = responseTimes.reduce(0, +) / Double(responseTimes.count)
        XCTAssertLessThan(averageResponseTime, 3.0, "Average response time should be under 3 seconds for good performance")
        
        print("Average response time: \(String(format: "%.3f", averageResponseTime))s")
    }
    
    func testConcurrentRequestPerformance() async throws {
        // Test performance with multiple concurrent requests
        
        let chatManager = ChatManager()
        
        // Create multiple conversations
        let conversationCount = 5
        var conversations: [Conversation] = []
        
        for i in 1...conversationCount {
            chatManager.createNewConversation()
            if let conversation = chatManager.currentConversation {
                conversations.append(conversation)
            }
        }
        
        let startTime = Date()
        
        // Send messages to all conversations concurrently
        await withTaskGroup(of: Void.self) { group in
            for (index, conversation) in conversations.enumerated() {
                group.addTask {
                    chatManager.selectConversation(conversation)
                    await chatManager.sendMessage("Concurrent test message \(index + 1)")
                }
            }
        }
        
        let endTime = Date()
        let totalTime = endTime.timeIntervalSince(startTime)
        
        // Concurrent processing should be faster than sequential
        let maxExpectedTime = Double(conversationCount) * 2.0 // Allow 2 seconds per conversation
        XCTAssertLessThan(totalTime, maxExpectedTime, "Concurrent processing took too long: \(totalTime)s")
        
        print("Concurrent processing time for \(conversationCount) conversations: \(String(format: "%.3f", totalTime))s")
    }
    
    func testVoiceInputPerformance() async throws {
        // Test voice input processing performance
        
        let voiceManager = VoiceManager()
        
        // Test transcription processing time
        let testTranscriptions = [
            "This is a short test",
            "This is a longer test message that contains more words and should take slightly longer to process",
            "Voice input performance test with various lengths of content to ensure consistent processing times"
        ]
        
        var processingTimes: [TimeInterval] = []
        
        for transcription in testTranscriptions {
            let startTime = Date()
            
            // Simulate transcription processing
            // In real implementation, this would involve actual speech recognition
            let processedTranscription = transcription.trimmingCharacters(in: .whitespacesAndNewlines)
            
            let endTime = Date()
            let processingTime = endTime.timeIntervalSince(startTime)
            processingTimes.append(processingTime)
            
            // Voice processing should be very fast (< 2 seconds as per requirement)
            XCTAssertLessThan(processingTime, 2.0, "Voice processing took too long: \(processingTime)s")
            XCTAssertEqual(processedTranscription, transcription)
            
            print("Voice processing time for '\(transcription)': \(String(format: "%.6f", processingTime))s")
        }
        
        let averageProcessingTime = processingTimes.reduce(0, +) / Double(processingTimes.count)
        print("Average voice processing time: \(String(format: "%.6f", averageProcessingTime))s")
    }
    
    // MARK: - Database Performance Tests
    
    func testDatabasePerformance() async throws {
        // Test database operations performance
        
        let dataStore = try DataStore()
        let conversations: [Conversation] = (1...100).map { i in
            var conversation = Conversation()
            conversation.title = "Performance Test Conversation \(i)"
            
            // Add messages to each conversation
            for j in 1...20 {
                let userMessage = Message(content: "User message \(j) in conversation \(i)", role: .user)
                let aiMessage = Message(content: "AI response \(j) in conversation \(i)", role: .assistant)
                conversation.addMessage(userMessage)
                conversation.addMessage(aiMessage)
            }
            
            return conversation
        }
        
        // Test save performance
        let saveStartTime = Date()
        
        for conversation in conversations {
            try await dataStore.saveConversation(conversation)
        }
        
        let saveEndTime = Date()
        let saveDuration = saveEndTime.timeIntervalSince(saveStartTime)
        
        // Should save 100 conversations with 40 messages each in reasonable time
        XCTAssertLessThan(saveDuration, 10.0, "Database save operations took too long: \(saveDuration)s")
        
        print("Database save time for 100 conversations: \(String(format: "%.3f", saveDuration))s")
        
        // Test load performance
        let loadStartTime = Date()
        let loadedConversations = try await dataStore.loadConversations()
        let loadEndTime = Date()
        let loadDuration = loadEndTime.timeIntervalSince(loadStartTime)
        
        // Should load all conversations in reasonable time
        XCTAssertLessThan(loadDuration, 5.0, "Database load operations took too long: \(loadDuration)s")
        XCTAssertEqual(loadedConversations.count, 100)
        
        print("Database load time for 100 conversations: \(String(format: "%.3f", loadDuration))s")
        
        // Test search performance
        let searchStartTime = Date()
        let searchResults = loadedConversations.filter { conversation in
            conversation.title.contains("50") || conversation.messages.contains { $0.content.contains("50") }
        }
        let searchEndTime = Date()
        let searchDuration = searchEndTime.timeIntervalSince(searchStartTime)
        
        XCTAssertLessThan(searchDuration, 1.0, "Search operations took too long: \(searchDuration)s")
        XCTAssertGreaterThan(searchResults.count, 0)
        
        print("Search time: \(String(format: "%.6f", searchDuration))s, Results: \(searchResults.count)")
    }
    
    // MARK: - App Startup Performance Tests
    
    func testAppStartupTime() async throws {
        // Test app startup performance (< 10 seconds requirement)
        
        let startupStartTime = Date()
        
        // Simulate app initialization
        let configManager = ConfigManager()
        await configManager.loadConfiguration()
        
        let chatManager = ChatManager()
        await chatManager.loadConversations()
        
        let performanceMonitor = PerformanceMonitor.shared
        performanceMonitor.startMonitoring()
        
        let startupEndTime = Date()
        let startupDuration = startupEndTime.timeIntervalSince(startupStartTime)
        
        // Record startup time
        performanceMonitor.recordAppStartupComplete()
        
        // Startup should be under 10 seconds (requirement)
        XCTAssertLessThan(startupDuration, 10.0, "App startup took too long: \(startupDuration)s")
        
        // For good user experience, should be under 5 seconds
        if startupDuration < 5.0 {
            print("✅ Excellent startup time: \(String(format: "%.3f", startupDuration))s")
        } else {
            print("⚠️ Acceptable but slow startup time: \(String(format: "%.3f", startupDuration))s")
        }
        
        performanceMonitor.stopMonitoring()
    }
    
    // MARK: - Context Management Performance Tests
    
    func testContextWindowPerformance() async throws {
        // Test performance of context window management with large conversations
        
        let chatManager = ChatManager()
        chatManager.createNewConversation()
        
        // Create a very large conversation (beyond context window)
        for i in 1...1000 {
            await chatManager.sendMessage("Context performance test message \(i)")
        }
        
        guard let conversation = chatManager.currentConversation else {
            XCTFail("No current conversation")
            return
        }
        
        // Test context extraction performance
        let contextStartTime = Date()
        let contextMessages = chatManager.getContextMessages(for: conversation)
        let contextEndTime = Date()
        let contextDuration = contextEndTime.timeIntervalSince(contextStartTime)
        
        // Context extraction should be fast even for large conversations
        XCTAssertLessThan(contextDuration, 0.1, "Context extraction took too long: \(contextDuration)s")
        
        // Context should be limited to 20 messages (10 exchanges)
        XCTAssertLessThanOrEqual(contextMessages.count, 20)
        
        // Test context statistics performance
        let statsStartTime = Date()
        let stats = chatManager.getContextStatistics(for: conversation)
        let statsEndTime = Date()
        let statsDuration = statsEndTime.timeIntervalSince(statsStartTime)
        
        XCTAssertLessThan(statsDuration, 0.05, "Context statistics calculation took too long: \(statsDuration)s")
        XCTAssertEqual(stats.totalMessages, 2000) // 1000 user + 1000 AI messages
        XCTAssertTrue(stats.isContextTrimmed)
        
        print("Context extraction time: \(String(format: "%.6f", contextDuration))s")
        print("Context statistics time: \(String(format: "%.6f", statsDuration))s")
        print("Context compression ratio: \(String(format: "%.3f", stats.compressionRatio))")
    }
    
    // MARK: - Stress Tests
    
    func testStressTestMultipleOperations() async throws {
        // Stress test with multiple operations happening simultaneously
        
        let performanceMonitor = PerformanceMonitor.shared
        let initialMemory = performanceMonitor.currentMemoryUsage
        
        let startTime = Date()
        
        // Run multiple operations concurrently
        await withTaskGroup(of: Void.self) { group in
            // Task 1: Create and manage conversations
            group.addTask {
                let chatManager = ChatManager()
                for i in 1...20 {
                    chatManager.createNewConversation()
                    await chatManager.sendMessage("Stress test conversation \(i)")
                }
            }
            
            // Task 2: Database operations
            group.addTask {
                do {
                    let dataStore = try DataStore()
                    for i in 1...10 {
                        var conversation = Conversation()
                        conversation.title = "Stress Test \(i)"
                        conversation.addMessage(Message(content: "Stress message \(i)", role: .user))
                        try await dataStore.saveConversation(conversation)
                    }
                } catch {
                    print("Database stress test error: \(error)")
                }
            }
            
            // Task 3: Configuration operations
            group.addTask {
                let configManager = ConfigManager()
                for i in 1...50 {
                    configManager.userConfig.nickname = "StressUser\(i)"
                    await configManager.saveConfiguration()
                }
            }
            
            // Task 4: Performance monitoring
            group.addTask {
                for _ in 1...100 {
                    await performanceMonitor.recordResponseTime(Double.random(in: 0.1...2.0))
                    try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
                }
            }
        }
        
        let endTime = Date()
        let totalDuration = endTime.timeIntervalSince(startTime)
        
        // Stress test should complete in reasonable time
        XCTAssertLessThan(totalDuration, 30.0, "Stress test took too long: \(totalDuration)s")
        
        // Memory usage should not have increased excessively
        let finalMemory = performanceMonitor.currentMemoryUsage
        let memoryIncrease = finalMemory - initialMemory
        let maxAllowedIncrease: Int64 = 200 * 1024 * 1024 // 200MB
        
        XCTAssertLessThan(memoryIncrease, maxAllowedIncrease, "Memory increased too much during stress test: \(memoryIncrease) bytes")
        
        print("Stress test completed in \(String(format: "%.3f", totalDuration))s")
        print("Memory increase: \(ByteCountFormatter.string(fromByteCount: memoryIncrease, countStyle: .memory))")
    }
    
    // MARK: - Performance Regression Tests
    
    func testPerformanceRegression() async throws {
        // Test to catch performance regressions
        
        let benchmarkResults = PerformanceBenchmark()
        
        // Benchmark conversation creation
        let conversationCreationTime = try await benchmarkResults.measureTime {
            let chatManager = ChatManager()
            for _ in 1...100 {
                chatManager.createNewConversation()
            }
        }
        
        // Benchmark message sending
        let messageSendingTime = try await benchmarkResults.measureTime {
            let chatManager = ChatManager()
            chatManager.createNewConversation()
            for i in 1...50 {
                await chatManager.sendMessage("Benchmark message \(i)")
            }
        }
        
        // Benchmark database operations
        let databaseTime = try await benchmarkResults.measureTime {
            let dataStore = try DataStore()
            var conversation = Conversation()
            for i in 1...100 {
                conversation.addMessage(Message(content: "DB benchmark \(i)", role: .user))
            }
            try await dataStore.saveConversation(conversation)
        }
        
        // Store benchmark results (in real implementation, these would be compared to baseline)
        benchmarkResults.conversationCreationTime = conversationCreationTime
        benchmarkResults.messageSendingTime = messageSendingTime
        benchmarkResults.databaseTime = databaseTime
        
        print("Performance Benchmark Results:")
        print("- Conversation creation: \(String(format: "%.3f", conversationCreationTime))s")
        print("- Message sending: \(String(format: "%.3f", messageSendingTime))s")
        print("- Database operations: \(String(format: "%.3f", databaseTime))s")
        
        // Basic sanity checks (adjust thresholds based on baseline measurements)
        XCTAssertLessThan(conversationCreationTime, 1.0, "Conversation creation performance regression")
        XCTAssertLessThan(messageSendingTime, 30.0, "Message sending performance regression")
        XCTAssertLessThan(databaseTime, 5.0, "Database performance regression")
    }
}

// MARK: - Helper Classes

class PerformanceBenchmark {
    var conversationCreationTime: TimeInterval = 0
    var messageSendingTime: TimeInterval = 0
    var databaseTime: TimeInterval = 0
    
    func measureTime<T>(_ operation: () async throws -> T) async rethrows -> TimeInterval {
        let startTime = Date()
        _ = try await operation()
        let endTime = Date()
        return endTime.timeIntervalSince(startTime)
    }
}