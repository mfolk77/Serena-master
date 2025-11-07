import XCTest
@testable import SerenaNet

@MainActor
final class MixtralEngineTests: XCTestCase {
    var engine: MixtralEngine!
    
    override func setUp() async throws {
        try await super.setUp()
        engine = MixtralEngine()
    }
    
    override func tearDown() async throws {
        await engine?.cleanup()
        engine = nil
        try await super.tearDown()
    }
    
    // MARK: - Initialization Tests
    
    func testInitialState() {
        XCTAssertFalse(engine.isReady)
        XCTAssertEqual(engine.loadingProgress, 0.0)
        XCTAssertGreaterThanOrEqual(engine.memoryUsage, 0) // May have small overhead for metrics
        XCTAssertEqual(engine.maxContextLength, 10)
    }
    
    func testInitialization() async throws {
        XCTAssertFalse(engine.isReady)
        
        try await engine.initialize()
        
        XCTAssertTrue(engine.isReady)
        XCTAssertEqual(engine.loadingProgress, 1.0)
        XCTAssertGreaterThan(engine.memoryUsage, 0)
    }
    
    func testDoubleInitialization() async throws {
        try await engine.initialize()
        XCTAssertTrue(engine.isReady)
        
        // Second initialization should not throw or change state
        try await engine.initialize()
        XCTAssertTrue(engine.isReady)
        XCTAssertEqual(engine.loadingProgress, 1.0)
    }
    
    // MARK: - Response Generation Tests
    
    func testGenerateResponseWhenNotReady() async {
        XCTAssertFalse(engine.isReady)
        
        do {
            _ = try await engine.generateResponse(for: "Hello", context: [])
            XCTFail("Should throw aiModelNotLoaded error")
        } catch SerenaError.aiModelNotLoaded {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateResponseWithEmptyPrompt() async throws {
        try await engine.initialize()
        
        do {
            _ = try await engine.generateResponse(for: "", context: [])
            XCTFail("Should throw emptyMessage error")
        } catch SerenaError.emptyMessage {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateResponseWithWhitespaceOnlyPrompt() async throws {
        try await engine.initialize()
        
        do {
            _ = try await engine.generateResponse(for: "   \n\t  ", context: [])
            XCTFail("Should throw emptyMessage error")
        } catch SerenaError.emptyMessage {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateResponseSuccess() async throws {
        try await engine.initialize()
        
        let response = try await engine.generateResponse(for: "Hello, how are you?", context: [])
        
        XCTAssertFalse(response.isEmpty)
        XCTAssertGreaterThan(response.count, 10) // Should be a meaningful response
    }
    
    func testGenerateResponseWithContext() async throws {
        try await engine.initialize()
        
        let context = [
            Message(content: "What is the weather like?", role: .user),
            Message(content: "I don't have access to current weather data.", role: .assistant)
        ]
        
        let response = try await engine.generateResponse(for: "Can you help me with something else?", context: context)
        
        XCTAssertFalse(response.isEmpty)
    }
    
    func testContextLimiting() async throws {
        try await engine.initialize()
        
        // Create more messages than maxContextLength
        var context: [Message] = []
        for i in 0..<15 {
            context.append(Message(content: "Message \(i)", role: i % 2 == 0 ? .user : .assistant))
        }
        
        let response = try await engine.generateResponse(for: "Final message", context: context)
        
        XCTAssertFalse(response.isEmpty)
        // The engine should handle the context limiting internally
    }
    
    // MARK: - Streaming Response Tests
    
    func testGenerateStreamingResponseWhenNotReady() async {
        XCTAssertFalse(engine.isReady)
        
        do {
            let _ = try await engine.generateStreamingResponse(for: "Hello", context: [])
            XCTFail("Should throw aiModelNotLoaded error")
        } catch SerenaError.aiModelNotLoaded {
            // Expected error
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGenerateStreamingResponseSuccess() async throws {
        try await engine.initialize()
        
        let stream = try await engine.generateStreamingResponse(for: "Tell me a story", context: [])
        
        var chunks: [String] = []
        for await chunk in stream {
            chunks.append(chunk)
        }
        
        XCTAssertGreaterThan(chunks.count, 0)
        
        let fullResponse = chunks.joined()
        XCTAssertFalse(fullResponse.isEmpty)
    }
    
    // MARK: - Memory Management Tests
    
    func testMemoryUsageTracking() async throws {
        let initialMemory = engine.memoryUsage
        XCTAssertGreaterThanOrEqual(initialMemory, 0)
        
        try await engine.initialize()
        
        XCTAssertGreaterThan(engine.memoryUsage, initialMemory)
    }
    
    func testCanHandleMemoryPressure() async throws {
        try await engine.initialize()
        
        // Initially should be able to handle memory pressure
        XCTAssertTrue(engine.canHandleMemoryPressure())
    }
    

    
    func testGetMemoryStats() async throws {
        try await engine.initialize()
        
        let stats = engine.getMemoryStats()
        
        XCTAssertGreaterThan(stats.totalMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(stats.modelMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(stats.cacheMemoryUsage, 0)
        XCTAssertGreaterThan(stats.availableMemory, 0)
    }
    
    // MARK: - Caching Tests
    
    func testResponseCaching() async throws {
        try await engine.initialize()
        
        let prompt = "What is 2 + 2?"
        let context: [Message] = []
        
        // First request
        let startTime1 = Date()
        let response1 = try await engine.generateResponse(for: prompt, context: context)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second request (should be cached)
        let startTime2 = Date()
        let response2 = try await engine.generateResponse(for: prompt, context: context)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        XCTAssertEqual(response1, response2)
        // Cached response should be significantly faster
        XCTAssertLessThan(duration2, duration1 * 0.5)
    }
    
    // MARK: - Configuration Tests
    
    func testConfigurationUpdate() async throws {
        try await engine.initialize()
        
        let newConfig = AIEngineConfiguration(
            temperature: 0.5,
            maxTokens: 500,
            topP: 0.8,
            frequencyPenalty: 0.1,
            presencePenalty: 0.1
        )
        
        engine.updateConfiguration(newConfig)
        
        // Configuration update should not affect engine readiness
        XCTAssertTrue(engine.isReady)
    }
    
    // MARK: - Cleanup Tests
    
    func testCleanup() async throws {
        try await engine.initialize()
        XCTAssertTrue(engine.isReady)
        XCTAssertGreaterThan(engine.memoryUsage, 0)
        
        await engine.cleanup()
        
        XCTAssertFalse(engine.isReady)
        XCTAssertEqual(engine.loadingProgress, 0.0)
        XCTAssertEqual(engine.memoryUsage, 0)
    }
    
    // MARK: - Error Handling Tests
    
    func testErrorHandlingDuringGeneration() async throws {
        try await engine.initialize()
        
        // Test with various edge cases
        let edgeCases = [
            String(repeating: "a", count: 10000), // Very long prompt
            "Special characters: !@#$%^&*()_+{}|:<>?[]\\;'\",./"
        ]
        
        for testCase in edgeCases {
            do {
                let response = try await engine.generateResponse(for: testCase, context: [])
                XCTAssertFalse(response.isEmpty)
            } catch {
                // Some edge cases might fail, but should be handled gracefully
                XCTAssertTrue(error is SerenaError)
            }
        }
    }
    
    // MARK: - Performance Tests
    
    func testResponseTimeRequirement() async throws {
        try await engine.initialize()
        
        let startTime = Date()
        let response = try await engine.generateResponse(for: "Quick test", context: [])
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertFalse(response.isEmpty)
        // Should meet the 5-second requirement from the specs
        XCTAssertLessThan(duration, 5.0)
    }
    
    func testInitializationTimeRequirement() async throws {
        let startTime = Date()
        try await engine.initialize()
        let duration = Date().timeIntervalSince(startTime)
        
        XCTAssertTrue(engine.isReady)
        // Should complete within 30 seconds as per requirements
        XCTAssertLessThan(duration, 30.0)
    }
    
    func testMemoryUsageRequirement() async throws {
        try await engine.initialize()
        
        // Generate several responses to build up memory usage
        for i in 0..<10 {
            _ = try await engine.generateResponse(for: "Test message \(i)", context: [])
        }
        
        // Should stay under 4GB requirement
        let maxMemoryBytes: Int64 = 4 * 1024 * 1024 * 1024 // 4GB
        XCTAssertLessThan(engine.memoryUsage, maxMemoryBytes)
    }
    
    // MARK: - Optimization Tests
    
    func testPerformanceMetricsTracking() async throws {
        try await engine.initialize()
        
        let initialMetrics = engine.getPerformanceMetrics()
        XCTAssertEqual(initialMetrics.totalInferences, 0)
        XCTAssertEqual(initialMetrics.cacheHits, 0)
        XCTAssertEqual(initialMetrics.cacheMisses, 0)
        
        // Generate some responses
        _ = try await engine.generateResponse(for: "Test 1", context: [])
        _ = try await engine.generateResponse(for: "Test 2", context: [])
        _ = try await engine.generateResponse(for: "Test 1", context: []) // Should be cached
        
        let finalMetrics = engine.getPerformanceMetrics()
        XCTAssertEqual(finalMetrics.totalInferences, 3)
        XCTAssertEqual(finalMetrics.cacheHits, 1) // Third request was cached
        XCTAssertEqual(finalMetrics.cacheMisses, 2) // First two were not cached
        XCTAssertGreaterThan(finalMetrics.averageInferenceTime, 0)
        XCTAssertGreaterThan(finalMetrics.cacheHitRate, 0)
    }
    
    func testEnhancedCaching() async throws {
        try await engine.initialize()
        
        let prompt = "What is machine learning?"
        let context: [Message] = []
        
        // First request - should not be cached
        let startTime1 = Date()
        let response1 = try await engine.generateResponse(for: prompt, context: context)
        let duration1 = Date().timeIntervalSince(startTime1)
        
        // Second request - should be cached and faster
        let startTime2 = Date()
        let response2 = try await engine.generateResponse(for: prompt, context: context)
        let duration2 = Date().timeIntervalSince(startTime2)
        
        XCTAssertEqual(response1, response2)
        XCTAssertLessThan(duration2, duration1 * 0.5) // Cached should be much faster
        
        let metrics = engine.getPerformanceMetrics()
        XCTAssertEqual(metrics.cacheHits, 1)
        XCTAssertEqual(metrics.cacheMisses, 1)
        XCTAssertEqual(metrics.cacheHitRate, 0.5)
    }
    
    func testMemoryPressureHandling() async throws {
        try await engine.initialize()
        
        // Generate many responses to build up cache
        for i in 0..<50 {
            _ = try await engine.generateResponse(for: "Test message \(i)", context: [])
        }
        
        let initialStats = engine.getMemoryStats()
        let initialCacheSize = initialStats.cacheMemoryUsage
        
        // Force memory pressure handling
        try await engine.handleMemoryPressure()
        
        let finalStats = engine.getMemoryStats()
        
        // Memory usage should be reduced or at least not increased
        XCTAssertLessThanOrEqual(finalStats.cacheMemoryUsage, initialCacheSize)
    }
    
    func testPerformanceOptimization() async throws {
        try await engine.initialize()
        
        // Generate responses with mixed access patterns
        _ = try await engine.generateResponse(for: "Frequent query", context: [])
        _ = try await engine.generateResponse(for: "Frequent query", context: [])
        _ = try await engine.generateResponse(for: "Frequent query", context: [])
        _ = try await engine.generateResponse(for: "Rare query", context: [])
        
        let initialStats = engine.getMemoryStats()
        
        // Optimize performance
        await engine.optimizePerformance()
        
        let finalStats = engine.getMemoryStats()
        
        // Should not significantly increase memory usage (allow small variance for optimization overhead)
        let memoryIncrease = finalStats.totalMemoryUsage - initialStats.totalMemoryUsage
        XCTAssertLessThan(memoryIncrease, 1_000_000) // Less than 1MB increase allowed
    }
    
    func testBackgroundProcessing() async throws {
        try await engine.initialize()
        
        // Test that multiple concurrent requests don't block each other
        let startTime = Date()
        
        async let response1 = engine.generateResponse(for: "Query 1", context: [])
        async let response2 = engine.generateResponse(for: "Query 2", context: [])
        async let response3 = engine.generateResponse(for: "Query 3", context: [])
        
        let responses = try await [response1, response2, response3]
        let totalDuration = Date().timeIntervalSince(startTime)
        
        // All responses should be valid
        for response in responses {
            XCTAssertFalse(response.isEmpty)
        }
        
        // Background processing should allow concurrent execution
        // Total time should be less than 3x single request time
        XCTAssertLessThan(totalDuration, 15.0) // Generous upper bound
        
        let metrics = engine.getPerformanceMetrics()
        XCTAssertGreaterThan(metrics.backgroundProcessingTasks, 0)
    }
    
    func testMemoryStatsAccuracy() async throws {
        try await engine.initialize()
        
        let stats = engine.getMemoryStats()
        
        XCTAssertGreaterThan(stats.totalMemoryUsage, 0)
        XCTAssertGreaterThan(stats.modelMemoryUsage, 0)
        XCTAssertGreaterThanOrEqual(stats.cacheMemoryUsage, 0)
        XCTAssertGreaterThan(stats.availableMemory, 0)
        
        // Total should be sum of components
        XCTAssertEqual(stats.totalMemoryUsage, stats.modelMemoryUsage + stats.cacheMemoryUsage)
    }
    
    func testPerformanceMetricsReset() async throws {
        try await engine.initialize()
        
        // Generate some activity
        _ = try await engine.generateResponse(for: "Test", context: [])
        
        let metricsBeforeReset = engine.getPerformanceMetrics()
        XCTAssertGreaterThan(metricsBeforeReset.totalInferences, 0)
        
        // Reset metrics
        engine.resetPerformanceMetrics()
        
        let metricsAfterReset = engine.getPerformanceMetrics()
        XCTAssertEqual(metricsAfterReset.totalInferences, 0)
        XCTAssertEqual(metricsAfterReset.cacheHits, 0)
        XCTAssertEqual(metricsAfterReset.cacheMisses, 0)
    }
}