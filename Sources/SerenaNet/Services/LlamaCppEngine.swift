import Foundation
import os.log

/// LlamaCpp-based LLM engine for running Mistral-7B and other GGUF models locally
@MainActor
final class LlamaCppEngine: AIEngine {
    @Published private(set) var isReady: Bool = false
    @Published private(set) var loadingProgress: Double = 0.0
    @Published private(set) var memoryUsage: Int64 = 0

    let maxContextLength: Int = 4096  // Matches --ctx-size for better memory
    private var configuration: AIEngineConfiguration = .default
    private let logger = Logger(subsystem: "com.serenanet.ai", category: "LlamaCppEngine")
    private var modelPath: URL?
    private var isInitializing = false

    private let defaultModelPaths = [
        "/Users/\(NSUserName())/Models/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
        "/Volumes/Folk_DAS/Developer/Serena/Models/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
        "~/Models/mistral-7b-instruct-v0.2.Q4_K_M.gguf",
    ]

    private var performanceMetrics = PerformanceMetrics()
    private var responseCache: [String: CachedResponse] = [:]
    private var cacheAccessOrder: [String] = []
    private let maxCacheSize = 50

    init(configuration: AIEngineConfiguration = .default) {
        self.configuration = configuration
    }

    func initialize() async throws {
        guard !isInitializing && !isReady else { return }
        isInitializing = true
        loadingProgress = 0.0

        do {
            loadingProgress = 0.2
            try await locateModel()
            loadingProgress = 0.5
            try await verifyLlamaCpp()
            loadingProgress = 0.8
            try await warmup()
            loadingProgress = 1.0
            isReady = true
            isInitializing = false
            logger.info("✅ LlamaCppEngine ready with model: \(self.modelPath?.lastPathComponent ?? "unknown")")
        } catch {
            isInitializing = false
            loadingProgress = 0.0
            logger.error("❌ LlamaCppEngine init failed: \(error.localizedDescription)")
            throw SerenaError.aiModelInitializationFailed(error.localizedDescription)
        }
    }

    func processInput(_ input: String, context: [Message]) async throws -> String {
        return try await generateResponse(for: input, context: context)
    }

    func generateResponse(for prompt: String, context: [Message]) async throws -> String {
        guard isReady else { throw SerenaError.aiModelNotLoaded }
        guard !prompt.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SerenaError.emptyMessage
        }

        let startTime = Date()
        let cacheKey = createCacheKey(prompt: prompt, context: context)

        if let cached = getCachedResponse(key: cacheKey) {
            let duration = Date().timeIntervalSince(startTime)
            performanceMetrics.recordInference(duration: duration, fromCache: true)
            return cached
        }

        let response = try await performInference(prompt: prompt, context: context)
        cacheResponse(key: cacheKey, response: response)

        let duration = Date().timeIntervalSince(startTime)
        performanceMetrics.recordInference(duration: duration, fromCache: false)

        return response
    }

    func generateStreamingResponse(for prompt: String, context: [Message]) async throws -> AsyncStream<String> {
        guard isReady else { throw SerenaError.aiModelNotLoaded }

        return AsyncStream { continuation in
            Task { @MainActor in
                do {
                    let response = try await self.performInference(prompt: prompt, context: context)
                    let words = response.components(separatedBy: .whitespacesAndNewlines)
                    for word in words {
                        continuation.yield(word + " ")
                        try await Task.sleep(nanoseconds: 50_000_000)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish()
                }
            }
        }
    }

    func cleanup() async {
        responseCache.removeAll()
        cacheAccessOrder.removeAll()
        isReady = false
    }

    func getPerformanceMetrics() -> PerformanceMetrics { return performanceMetrics }
    func resetPerformanceMetrics() { performanceMetrics = PerformanceMetrics() }
    func optimizePerformance() async {}
    func canHandleMemoryPressure() -> Bool { return true }
    func handleMemoryPressure() async throws {
        responseCache.removeAll()
        cacheAccessOrder.removeAll()
    }
    func updateConfiguration(_ newConfiguration: AIEngineConfiguration) {
        configuration = newConfiguration
    }

    func getMemoryStats() -> AIEngineMemoryStats {
        let modelMemory: Int64 = isReady ? 6_500_000_000 : 0
        let cacheMemory: Int64 = Int64(responseCache.values.reduce(0) { $0 + $1.memorySize })
        let totalMemory = modelMemory + cacheMemory
        memoryUsage = totalMemory

        return AIEngineMemoryStats(
            totalMemoryUsage: totalMemory,
            modelMemoryUsage: modelMemory,
            cacheMemoryUsage: cacheMemory,
            availableMemory: Int64(ProcessInfo.processInfo.physicalMemory) - totalMemory,
            memoryPressureLevel: .normal
        )
    }

    private func locateModel() async throws {
        for pathString in defaultModelPaths {
            let expandedPath = NSString(string: pathString).expandingTildeInPath
            let url = URL(fileURLWithPath: expandedPath)

            if FileManager.default.fileExists(atPath: url.path) {
                modelPath = url
                logger.info("✅ Found model: \(url.path)")
                return
            }
        }
        throw SerenaError.aiModelInitializationFailed("Mistral-7B not found")
    }

    private func verifyLlamaCpp() async throws {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/llama-cli")
        process.arguments = ["--version"]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                logger.info("✅ llama.cpp verified")
                return
            }
        } catch {
            logger.warning("⚠️ llama.cpp check failed")
        }
    }

    private func warmup() async throws {
        try await Task.sleep(nanoseconds: 500_000_000)
    }

    private func performInference(prompt: String, context: [Message]) async throws -> String {
        guard let modelPath = modelPath else { throw SerenaError.aiModelNotLoaded }

        let fullPrompt = buildPrompt(userMessage: prompt, context: context)
        return try await runLlamaCppInference(prompt: fullPrompt, modelPath: modelPath)
    }

    private func runLlamaCppInference(prompt: String, modelPath: URL) async throws -> String {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/opt/homebrew/bin/llama-cli")
        process.arguments = [
            "--model", modelPath.path,
            "--prompt", prompt,
            "--n-predict", "512",
            "--temp", "0.85",              // More creative/natural responses
            "--top-k", "50",               // More diverse token selection
            "--top-p", "0.95",             // Smoother probability distribution
            "--repeat-penalty", "1.15",    // Reduce repetition
            "--ctx-size", "4096",          // Better conversation memory
            "--threads", "8",
            "--no-display-prompt"
        ]

        let outputPipe = Pipe()
        process.standardOutput = outputPipe
        process.standardError = Pipe()

        try process.run()
        let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()

        if process.terminationStatus == 0,
           let output = String(data: outputData, encoding: .utf8) {
            return output.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        return "I'm in fallback mode. Please check llama.cpp setup."
    }

    private func buildPrompt(userMessage: String, context: [Message]) -> String {
        var prompt = "<s>[INST] "
        let recentContext = Array(context.suffix(5))
        for message in recentContext {
            if message.role == .user {
                prompt += message.content + " "
            } else {
                prompt += "[/INST] " + message.content + " </s><s>[INST] "
            }
        }
        prompt += userMessage + " [/INST]"
        return prompt
    }

    private func createCacheKey(prompt: String, context: [Message]) -> String {
        let contextHash = context.suffix(3).map { "\($0.content.prefix(50))" }.joined(separator: "|")
        return "\(prompt.prefix(100).hashValue)_\(contextHash.hashValue)"
    }

    private func getCachedResponse(key: String) -> String? {
        guard let cached = responseCache[key] else { return nil }
        cacheAccessOrder.removeAll { $0 == key }
        cacheAccessOrder.append(key)
        responseCache[key] = cached.accessed()
        return cached.response
    }

    private func cacheResponse(key: String, response: String) {
        if responseCache.count >= maxCacheSize {
            if let oldest = cacheAccessOrder.first {
                cacheAccessOrder.removeFirst()
                responseCache.removeValue(forKey: oldest)
            }
        }
        responseCache[key] = CachedResponse(response: response)
        cacheAccessOrder.append(key)
    }
}

private struct CachedResponse {
    let response: String
    let timestamp: Date
    let accessCount: Int
    let memorySize: Int

    init(response: String) {
        self.response = response
        self.timestamp = Date()
        self.accessCount = 1
        self.memorySize = response.utf8.count + 64
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
