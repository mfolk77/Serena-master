import Foundation
import os.log
import CoreML

/// Model precision options for Mixtral
enum ModelPrecision: String, CaseIterable {
    case quantized = "quantized"
    case fp16 = "fp16"
    case fp32 = "fp32"
    
    var subdirectory: String {
        return self.rawValue
    }
    
    var description: String {
        switch self {
        case .quantized:
            return "Quantized (Q4_K_M)"
        case .fp16:
            return "Half Precision (FP16)"
        case .fp32:
            return "Full Precision (FP32)"
        }
    }
}

/// Mixtral MoE AI Engine implementation for local AI processing
@MainActor
final class MixtralEngine: AIEngine {
    // MARK: - Published Properties
    @Published private(set) var isReady: Bool = false
    @Published private(set) var loadingProgress: Double = 0.0
    @Published private(set) var memoryUsage: Int64 = 0
    
    // MARK: - Configuration
    let maxContextLength: Int = 10 // 10 prior exchanges as per requirements
    private var configuration: AIEngineConfiguration = .default
    
    // MARK: - Private Properties
    private var llamaEngine: LlamaCppEngine? // Real AI engine using llama.cpp
    private var modelConfig: MixtralModelConfig?
    private var isInitializing: Bool = false
    private let logger = Logger(subsystem: "com.serenanet.ai", category: "MixtralEngine")
    private var memoryMonitorTimer: Timer?
    
    // Enhanced caching system
    private var responseCache: [String: CachedResponse] = [:]
    private var cacheAccessOrder: [String] = [] // For LRU implementation
    private let maxCacheSize = 100
    
    // Background processing
    private let backgroundQueue = DispatchQueue(label: "com.serenanet.ai.background", qos: .userInitiated)
    private let inferenceQueue = DispatchQueue(label: "com.serenanet.ai.inference", qos: .userInitiated)
    
    // Performance monitoring
    private var performanceMetrics = PerformanceMetrics()
    private var lastMemoryCleanup = Date()
    private let memoryCleanupInterval: TimeInterval = 300 // 5 minutes
    private let performanceMonitor = PerformanceMonitor.shared
    
    // Model paths
    private let modelDirectory = "Models/Mixtral-8x7B-MoE"
    private let preferredModelType: ModelPrecision = .quantized // Start with quantized for better performance
    
    // Performance tracking
    private var totalProcessingTime: TimeInterval = 0
    private var totalRequests: Int = 0
    private var maxProcessingTime: TimeInterval = 0
    
    // MARK: - Memory Management
    private var currentMemoryStats = AIEngineMemoryStats(
        totalMemoryUsage: 0,
        modelMemoryUsage: 0,
        cacheMemoryUsage: 0,
        availableMemory: 0,
        memoryPressureLevel: .normal
    )
    
    init(configuration: AIEngineConfiguration = .default) {
        self.configuration = configuration
        startMemoryMonitoring()
    }
    
    deinit {
        memoryMonitorTimer?.invalidate()
    }
    
    // MARK: - AIEngine Protocol Implementation
    
    func initialize() async throws {
        print("🔍 DEBUG: MixtralEngine.initialize() called")
        
        guard !isInitializing && !isReady else {
            logger.info("MixtralEngine already initialized or initializing")
            print("🔍 DEBUG: Already initializing or ready, returning")
            return
        }
        
        isInitializing = true
        loadingProgress = 0.0
        
        logger.info("Starting MixtralEngine initialization")
        print("🔍 DEBUG: Starting initialization process")
        
        do {
            // Simulate model loading phases
            print("🔍 DEBUG: About to call loadModelFiles()")
            try await loadModelFiles()
            print("🔍 DEBUG: loadModelFiles() completed")
            loadingProgress = 0.3
            
            try await initializeModel()
            loadingProgress = 0.6
            
            try await validateModel()
            loadingProgress = 0.8
            
            try await warmupModel()
            loadingProgress = 1.0
            
            isReady = true
            isInitializing = false
            
            logger.info("MixtralEngine initialization completed successfully")
            
        } catch {
            isInitializing = false
            loadingProgress = 0.0
            logger.error("MixtralEngine initialization failed: \(error.localizedDescription)")
            throw SerenaError.aiModelInitializationFailed(error.localizedDescription)
        }
    }
    
    func generateResponse(for prompt: String, context: [Message]) async throws -> String {
        guard isReady else {
            throw SerenaError.aiModelNotLoaded
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SerenaError.emptyMessage
        }
        
        logger.info("Generating response for prompt (length: \(prompt.count))")
        
        let startTime = Date()
        
        // Check cache first
        let cacheKey = createCacheKey(prompt: prompt, context: context)
        if let cachedResponse = getCachedResponse(key: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            performanceMetrics.recordInference(duration: duration, fromCache: true)
            logger.info("Returning cached response (cache hit rate: \(String(format: "%.1f", self.performanceMetrics.cacheHitRate * 100))%)")
            return cachedResponse
        }
        
        // Perform background inference to avoid blocking UI
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                do {
                    let response = try await self.performBackgroundInference(prompt: prompt, context: context)
                    
                    // Cache the response
                    await MainActor.run {
                        self.cacheResponse(key: cacheKey, response: response)
                        let duration = Date().timeIntervalSince(startTime)
                        self.performanceMetrics.recordInference(duration: duration, fromCache: false)
                        
                        self.logger.info("Response generated successfully (length: \(response.count), time: \(String(format: "%.2f", duration))s, avg: \(String(format: "%.2f", self.performanceMetrics.averageInferenceTime))s)")
                    }
                    
                    continuation.resume(returning: response)
                    
                } catch {
                    await MainActor.run {
                        self.logger.error("Response generation failed: \(error.localizedDescription)")
                    }
                    continuation.resume(throwing: SerenaError.aiResponseGenerationFailed(error.localizedDescription))
                }
            }
        }
    }
    
    private func performBackgroundInference(prompt: String, context: [Message]) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            inferenceQueue.async {
                Task {
                    do {
                        await MainActor.run {
                            self.performanceMetrics.recordBackgroundTask()
                        }
                        
                        let response = try await self.performInference(prompt: prompt, context: context)
                        continuation.resume(returning: response)
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        }
    }
    
    func generateStreamingResponse(for prompt: String, context: [Message]) async throws -> AsyncStream<String> {
        guard isReady else {
            throw SerenaError.aiModelNotLoaded
        }
        
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SerenaError.emptyMessage
        }
        
        logger.info("Generating streaming response for prompt")
        
        return AsyncStream { continuation in
            Task { @MainActor [weak self] in
                guard let self = self else {
                    continuation.finish()
                    return
                }
                
                do {
                    // For streaming, we'll generate the response in real-time chunks
                    // This provides a better user experience than generating the full response first
                    try await self.generateStreamingInference(prompt: prompt, context: context, continuation: continuation)
                    
                } catch {
                    self.logger.error("Streaming response generation failed: \(error.localizedDescription)")
                    continuation.finish()
                }
            }
        }
    }
    
    private func generateStreamingInference(prompt: String, context: [Message], continuation: AsyncStream<String>.Continuation) async throws {
        guard let llamaEngine = llamaEngine, llamaEngine.isReady else {
            logger.error("Cannot stream: LlamaCppEngine not ready")
            continuation.finish()
            return
        }

        // Prepare context for inference
        let contextMessages = prepareContext(context)

        logger.debug("Streaming real AI inference with context length: \(contextMessages.count)")

        do {
            // Use LlamaCppEngine's streaming capability
            let stream = try await llamaEngine.generateStreamingResponse(for: prompt, context: contextMessages)

            for await chunk in stream {
                continuation.yield(chunk)
            }

            continuation.finish()

        } catch {
            logger.error("Streaming inference failed: \(error.localizedDescription)")
            continuation.finish()
        }
    }
    
    func cleanup() async {
        logger.info("Cleaning up MixtralEngine")

        // Log final performance metrics
        if performanceMetrics.totalInferences > 0 {
            logger.info("Final performance metrics - Total inferences: \(self.performanceMetrics.totalInferences), Average time: \(String(format: "%.2f", self.performanceMetrics.averageInferenceTime))s, Cache hit rate: \(String(format: "%.1f", self.performanceMetrics.cacheHitRate * 100))%, Memory pressure events: \(self.performanceMetrics.memoryPressureEvents)")
        }

        // Clean up LlamaCppEngine
        if let llamaEngine = llamaEngine {
            await llamaEngine.cleanup()
        }

        memoryMonitorTimer?.invalidate()
        responseCache.removeAll()
        cacheAccessOrder.removeAll()
        performanceMetrics = PerformanceMetrics()
        llamaEngine = nil
        isReady = false
        loadingProgress = 0.0
        memoryUsage = 0

        logger.info("MixtralEngine cleanup completed")
    }
    
    // MARK: - Performance Monitoring
    
    func getPerformanceMetrics() -> PerformanceMetrics {
        return performanceMetrics
    }
    
    func resetPerformanceMetrics() {
        performanceMetrics = PerformanceMetrics()
        logger.info("Performance metrics reset")
    }
    
    func optimizePerformance() async {
        logger.info("Optimizing AI engine performance")
        
        // Optimize cache based on usage patterns
        await optimizeCache()
        
        // Perform memory cleanup if needed
        if currentMemoryStats.memoryPressureLevel != .normal {
            do {
                try await handleMemoryPressure()
            } catch {
                logger.error("Performance optimization memory cleanup failed: \(error.localizedDescription)")
            }
        }
        
        // Update memory usage after optimization
        updateMemoryUsage()
        
        logger.info("Performance optimization completed")
    }
    
    private func optimizeCache() async {
        logger.debug("Optimizing response cache")
        
        let initialCacheSize = responseCache.count
        
        // Remove entries that haven't been accessed recently and have low access counts
        let cutoffDate = Date().addingTimeInterval(-1800) // 30 minutes ago
        let lowAccessThreshold = 2
        
        let keysToRemove = responseCache.compactMap { key, value in
            (value.timestamp < cutoffDate && value.accessCount < lowAccessThreshold) ? key : nil
        }
        
        for key in keysToRemove {
            responseCache.removeValue(forKey: key)
            cacheAccessOrder.removeAll { $0 == key }
        }
        
        // Reorder cache access list to reflect actual usage
        let sortedByAccess = responseCache.sorted { $0.value.accessCount > $1.value.accessCount }
        cacheAccessOrder = sortedByAccess.map { $0.key }
        
        let removedCount = initialCacheSize - responseCache.count
        if removedCount > 0 {
            logger.debug("Cache optimization removed \(removedCount) underused entries")
        }
    }
    
    func canHandleMemoryPressure() async -> Bool {
        await updateMemoryStats()
        return currentMemoryStats.memoryPressureLevel != .critical
    }
    
    // MARK: - Helper Methods
    
    
    private func updateMemoryStats() async {
        // Update memory usage first
        updateMemoryUsage()
        
        // Calculate memory pressure level
        let physicalMemory = Int64(ProcessInfo.processInfo.physicalMemory)
        let availableMemory = physicalMemory - memoryUsage
        let availablePercentage = Double(availableMemory) / Double(physicalMemory)
        
        let pressureLevel: MemoryPressureLevel
        switch availablePercentage {
        case 0.5...:
            pressureLevel = .normal
        case 0.1..<0.5:
            pressureLevel = .warning
        default:
            pressureLevel = .critical
        }
        
        // Update current memory stats
        currentMemoryStats = AIEngineMemoryStats(
            totalMemoryUsage: memoryUsage,
            modelMemoryUsage: memoryUsage - Int64(getCacheMemoryUsage()),
            cacheMemoryUsage: Int64(getCacheMemoryUsage()),
            availableMemory: availableMemory,
            memoryPressureLevel: pressureLevel
        )
    }
    
    private func updatePerformanceMetrics(processingTime: TimeInterval) async {
        // Update internal performance tracking
        totalProcessingTime += processingTime
        totalRequests += 1
        
        if processingTime > maxProcessingTime {
            maxProcessingTime = processingTime
        }
        
        // Update memory stats after processing
        await updateMemoryStats()
    }
    
    func handleMemoryPressure() async throws {
        logger.warning("Handling memory pressure (level: \(self.currentMemoryStats.memoryPressureLevel.description))")
        
        performanceMetrics.recordMemoryPressure()
        
        switch self.currentMemoryStats.memoryPressureLevel {
        case .normal:
            // Perform routine cleanup if it's been a while
            if Date().timeIntervalSince(lastMemoryCleanup) > memoryCleanupInterval {
                await performRoutineCleanup()
            }
            return
            
        case .warning:
            await performModerateCleanup()
            await performAggressiveCleanup()
            
        case .critical:
            try await performCriticalCleanup()
        }
        
        lastMemoryCleanup = Date()
        updateMemoryUsage()
    }
    
    private func performRoutineCleanup() async {
        logger.debug("Performing routine memory cleanup")
        
        // Remove old cache entries (older than 1 hour)
        let oneHourAgo = Date().addingTimeInterval(-3600)
        let keysToRemove = responseCache.compactMap { key, value in
            value.timestamp < oneHourAgo ? key : nil
        }
        
        for key in keysToRemove {
            responseCache.removeValue(forKey: key)
            cacheAccessOrder.removeAll { $0 == key }
        }
        
        logger.debug("Routine cleanup removed \(keysToRemove.count) old cache entries")
    }
    
    private func performModerateCleanup() async {
        logger.info("Performing moderate memory cleanup")
        
        // Remove least recently used cache entries (keep only 50% of cache)
        let targetSize = maxCacheSize / 2
        while responseCache.count > targetSize && !cacheAccessOrder.isEmpty {
            let oldestKey = cacheAccessOrder.removeFirst()
            responseCache.removeValue(forKey: oldestKey)
        }
        
        logger.info("Moderate cleanup reduced cache to \(self.responseCache.count) entries")
    }
    
    private func performAggressiveCleanup() async {
        logger.warning("Performing aggressive memory cleanup")
        
        // Clear most of the cache, keeping only frequently accessed items
        let frequentlyUsedThreshold = 3
        let frequentlyUsed = responseCache.filter { $0.value.accessCount >= frequentlyUsedThreshold }
        
        responseCache = frequentlyUsed
        cacheAccessOrder = Array(frequentlyUsed.keys)
        
        // Force garbage collection hint
        autoreleasepool {
            // This helps trigger garbage collection
        }
        
        logger.warning("Aggressive cleanup kept \(self.responseCache.count) frequently used cache entries")
    }
    
    private func performCriticalCleanup() async throws {
        logger.error("Performing critical memory cleanup")
        
        // Clear all caches
        responseCache.removeAll()
        cacheAccessOrder.removeAll()
        
        // Reset performance metrics to free memory
        performanceMetrics = PerformanceMetrics()
        
        // Consider temporarily reducing model precision or unloading non-essential components
        if let currentConfig = modelConfig, currentConfig.precision == .fp16 {
            logger.warning("Critical memory pressure: Consider switching to quantized model")
            // In a real implementation, we might reload with quantized precision
        }
        
        // Force garbage collection
        autoreleasepool {
            // This helps trigger garbage collection
        }
        
        logger.error("Critical cleanup completed - functionality may be limited")
        
        // If we still can't handle the pressure, throw an error
        if !(await canHandleMemoryPressure()) {
            throw SerenaError.aiProcessingError("Critical memory pressure - AI functionality temporarily limited")
        }
    }
    
    // MARK: - Private Implementation
    
    private func loadModelFiles() async throws {
        logger.info("Initializing LlamaCpp engine for real AI inference")
        print("🔍 DEBUG: loadModelFiles() called - creating LlamaCppEngine")

        // Create LlamaCppEngine instance for real AI
        llamaEngine = LlamaCppEngine(configuration: configuration)

        logger.info("LlamaCppEngine created successfully")
        updateMemoryUsage()
    }
    
    private func isRunningInTestEnvironment() -> Bool {
        return ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil ||
               NSClassFromString("XCTest") != nil
    }
    
    private func initializeModel() async throws {
        logger.info("Initializing real AI model via LlamaCppEngine")

        guard let llamaEngine = llamaEngine else {
            throw SerenaError.aiModelInitializationFailed("LlamaCppEngine not available")
        }

        do {
            // Initialize the real llama.cpp engine with Mistral model
            logger.info("Calling LlamaCppEngine.initialize() for Mistral-7B")
            try await llamaEngine.initialize()

            logger.info("✅ Real AI model initialized successfully via LlamaCppEngine")
            print("✅ Real Mistral-7B model ready for conversations")

        } catch {
            logger.error("Failed to initialize LlamaCppEngine: \(error.localizedDescription)")
            throw SerenaError.aiModelInitializationFailed("Could not load Mistral model: \(error.localizedDescription)")
        }

        updateMemoryUsage()
    }
    
    private func validateModel() async throws {
        logger.info("Validating AI model via LlamaCppEngine")

        guard let llamaEngine = llamaEngine, llamaEngine.isReady else {
            throw SerenaError.aiModelInitializationFailed("LlamaCppEngine not ready")
        }

        logger.info("✅ Model validation successful - LlamaCppEngine ready")
    }

    private func warmupModel() async throws {
        logger.info("Warming up AI model")

        // LlamaCppEngine handles its own warmup during initialization
        // No additional warmup needed

        updateMemoryUsage()
    }
    
    private func performInference(prompt: String, context: [Message]) async throws -> String {
        guard let llamaEngine = llamaEngine, llamaEngine.isReady else {
            throw SerenaError.aiModelNotLoaded
        }

        // Prepare context for inference (limit to our maxContextLength)
        let contextMessages = prepareContext(context)

        logger.debug("Performing REAL AI inference with context length: \(contextMessages.count)")

        do {
            // Delegate to LlamaCppEngine for real AI inference
            let response = try await llamaEngine.generateResponse(for: prompt, context: contextMessages)

            logger.debug("✅ Real AI response generated (length: \(response.count))")
            updateMemoryUsage()
            return response

        } catch {
            logger.error("Real AI inference failed: \(error.localizedDescription)")
            throw SerenaError.aiResponseGenerationFailed("Inference error: \(error.localizedDescription)")
        }
    }
    
    
    private func prepareContext(_ messages: [Message]) -> [Message] {
        // Limit context to maxContextLength messages, keeping the most recent
        let recentMessages = Array(messages.suffix(maxContextLength))

        logger.debug("Prepared context with \(recentMessages.count) messages")
        return recentMessages
    }

    private func createCacheKey(prompt: String, context: [Message]) -> String {
        // Create a more sophisticated cache key that considers context relevance
        let contextHash = context.suffix(5).map { "\($0.role.rawValue):\($0.content.prefix(100))" }.joined(separator: "|")
        let promptHash = prompt.prefix(200).hashValue
        return "\(promptHash)_\(contextHash.hashValue)"
    }
    
    private func getCachedResponse(key: String) -> String? {
        guard let cachedResponse = responseCache[key] else {
            return nil
        }
        
        // Update access order for LRU
        cacheAccessOrder.removeAll { $0 == key }
        cacheAccessOrder.append(key)
        
        // Update access count
        responseCache[key] = cachedResponse.accessed()
        
        return cachedResponse.response
    }
    
    private func cacheResponse(key: String, response: String) {
        // Implement proper LRU cache behavior
        if responseCache.count >= maxCacheSize {
            // Remove least recently used entries
            while responseCache.count >= maxCacheSize && !cacheAccessOrder.isEmpty {
                let lruKey = cacheAccessOrder.removeFirst()
                responseCache.removeValue(forKey: lruKey)
            }
        }
        
        // Add new response
        responseCache[key] = CachedResponse(response: response)
        cacheAccessOrder.append(key)
        
        logger.debug("Cached response (cache size: \(self.responseCache.count), total memory: \(self.getCacheMemoryUsage()) bytes)")
    }
    
    private func getCacheMemoryUsage() -> Int {
        return responseCache.values.reduce(0) { $0 + $1.memorySize }
    }
    
    private func chunkResponse(_ response: String) -> [String] {
        // Split response into chunks for streaming
        let words = response.components(separatedBy: .whitespaces)
        var chunks: [String] = []
        var currentChunk = ""
        
        for word in words {
            if currentChunk.count + word.count + 1 > 20 { // Chunk size ~20 characters
                if !currentChunk.isEmpty {
                    chunks.append(currentChunk + " ")
                    currentChunk = word
                } else {
                    chunks.append(word + " ")
                }
            } else {
                currentChunk += (currentChunk.isEmpty ? "" : " ") + word
            }
        }
        
        if !currentChunk.isEmpty {
            chunks.append(currentChunk)
        }
        
        return chunks
    }
    
    private func startMemoryMonitoring() {
        // Update memory usage immediately
        updateMemoryUsage()
        
        memoryMonitorTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.updateMemoryUsage()
            }
        }
    }
    
    private func updateMemoryUsage() {
        // Calculate realistic memory usage based on model state and precision
        var baseMemoryUsage: Int64 = 0
        
        if isReady || isInitializing {
            // Memory usage varies by model precision
            switch modelConfig?.precision {
            case .quantized:
                baseMemoryUsage = 1_500_000_000 // ~1.5GB for quantized model
            case .fp16:
                baseMemoryUsage = 3_000_000_000 // ~3GB for fp16 model
            case .fp32:
                baseMemoryUsage = 6_000_000_000 // ~6GB for fp32 model
            case .none:
                baseMemoryUsage = 500_000_000   // ~500MB for initialization overhead
            }
        }
        
        // Calculate actual cache memory usage
        let actualCacheMemoryUsage: Int64 = Int64(getCacheMemoryUsage())

        // Add performance metrics memory usage
        let metricsMemoryUsage: Int64 = 1_000_000 // ~1MB for metrics

        let totalUsage = baseMemoryUsage + actualCacheMemoryUsage + metricsMemoryUsage
        memoryUsage = totalUsage
        
        // Get system memory info with better accuracy
        let physicalMemory = ProcessInfo.processInfo.physicalMemory
        
        // Estimate available memory more accurately
        var availableMemory: Int64
        if #available(macOS 12.0, *) {
            // Use more accurate memory calculation on newer systems
            let usedMemory = totalUsage
            availableMemory = max(Int64(physicalMemory) - usedMemory, 0)
        } else {
            // Fallback for older systems
            availableMemory = max(Int64(physicalMemory) - totalUsage, 0)
        }
        
        // Determine memory pressure level with more nuanced thresholds
        let usagePercentage = Double(totalUsage) / Double(physicalMemory)
        let availablePercentage = Double(availableMemory) / Double(physicalMemory)
        
        let pressureLevel: MemoryPressureLevel
        switch (usagePercentage, availablePercentage) {
        case (_, let available) where available > 0.4:
            pressureLevel = .normal
        case (_, let available) where available > 0.1:
            pressureLevel = .warning
        default:
            pressureLevel = .critical
        }
        
        currentMemoryStats = AIEngineMemoryStats(
            totalMemoryUsage: totalUsage,
            modelMemoryUsage: baseMemoryUsage,
            cacheMemoryUsage: actualCacheMemoryUsage + metricsMemoryUsage,
            availableMemory: availableMemory,
            memoryPressureLevel: pressureLevel
        )
        
        // Proactive memory pressure handling
        if pressureLevel != .normal {
            logger.warning("Memory pressure detected: \(pressureLevel.description) (usage: \(String(format: "%.1f", usagePercentage * 100))%, available: \(String(format: "%.1f", availablePercentage * 100))%)")
            
            // Trigger automatic cleanup for high pressure
            if pressureLevel == .warning || pressureLevel == .critical {
                Task {
                    do {
                        try await self.handleMemoryPressure()
                    } catch {
                        self.logger.error("Automatic memory pressure handling failed: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        // Log detailed memory stats periodically or when pressure is detected
        let shouldLogDetails = pressureLevel != .normal || Int.random(in: 1...20) == 1
        if shouldLogDetails {
            logger.debug("Memory stats - Total: \(ByteCountFormatter.string(fromByteCount: totalUsage, countStyle: .memory)), Model: \(ByteCountFormatter.string(fromByteCount: baseMemoryUsage, countStyle: .memory)), Cache: \(ByteCountFormatter.string(fromByteCount: actualCacheMemoryUsage, countStyle: .memory)) (\(self.responseCache.count) entries), Available: \(ByteCountFormatter.string(fromByteCount: availableMemory, countStyle: .memory))")
            
            // Log performance metrics occasionally
            if performanceMetrics.totalInferences > 0 {
                logger.debug("Performance - Inferences: \(self.performanceMetrics.totalInferences), Avg time: \(String(format: "%.2f", self.performanceMetrics.averageInferenceTime))s, Cache hit rate: \(String(format: "%.1f", self.performanceMetrics.cacheHitRate * 100))%, Memory events: \(self.performanceMetrics.memoryPressureEvents)")
            }
        }
    }
    
    // MARK: - Public Configuration
    
    func updateConfiguration(_ newConfiguration: AIEngineConfiguration) async {
        configuration = newConfiguration
        logger.info("Updated AI engine configuration")
    }
    
    func getMemoryStats() async -> AIEngineMemoryStats {
        return currentMemoryStats
    }
    
    func processInput(_ input: String, context: [Message]) async throws -> String {
        return try await generateResponse(for: input, context: context)
    }
    


}

// MARK: - Supporting Types

/// Enhanced cached response with metadata
private struct CachedResponse {
    let response: String
    let timestamp: Date
    let accessCount: Int
    let memorySize: Int
    
    init(response: String) {
        self.response = response
        self.timestamp = Date()
        self.accessCount = 1
        self.memorySize = response.utf8.count + 64 // Approximate overhead
    }
    
    func accessed() -> CachedResponse {
        return CachedResponse(
            response: self.response,
            timestamp: self.timestamp,
            accessCount: self.accessCount + 1,
            memorySize: self.memorySize
        )
    }
    
    private init(response: String, timestamp: Date, accessCount: Int, memorySize: Int) {
        self.response = response
        self.timestamp = timestamp
        self.accessCount = accessCount
        self.memorySize = memorySize
    }
}

/// Performance metrics tracking
public struct PerformanceMetrics {
    var totalInferences: Int = 0
    var totalInferenceTime: TimeInterval = 0
    var cacheHits: Int = 0
    var cacheMisses: Int = 0
    var memoryPressureEvents: Int = 0
    var backgroundProcessingTasks: Int = 0
    
    var averageInferenceTime: TimeInterval {
        guard totalInferences > 0 else { return 0 }
        return totalInferenceTime / Double(totalInferences)
    }
    
    var cacheHitRate: Double {
        let totalRequests = cacheHits + cacheMisses
        guard totalRequests > 0 else { return 0 }
        return Double(cacheHits) / Double(totalRequests)
    }
    
    mutating func recordInference(duration: TimeInterval, fromCache: Bool) {
        totalInferences += 1
        totalInferenceTime += duration
        
        if fromCache {
            cacheHits += 1
        } else {
            cacheMisses += 1
        }
    }
    
    mutating func recordMemoryPressure() {
        memoryPressureEvents += 1
    }
    
    mutating func recordBackgroundTask() {
        backgroundProcessingTasks += 1
    }
}

struct MixtralModelConfig {
    let precision: ModelPrecision
    let modelPath: URL
    let vocabularySize: Int
    let contextLength: Int
    let hiddenSize: Int
    
    static func create(for precision: ModelPrecision, modelPath: URL) -> MixtralModelConfig {
        return MixtralModelConfig(
            precision: precision,
            modelPath: modelPath,
            vocabularySize: 32000,
            contextLength: 32768,
            hiddenSize: precision == .quantized ? 4096 : 8192
        )
    }
}

