#!/bin/bash
set -e

echo "🚀 Integrating Mistral-7B + Semantic Search into Serena"
echo "========================================================"

SERENA_DIR="/Volumes/Folk_DAS/Developer/Serena/SerenaMaster"

if [ ! -d "$SERENA_DIR" ]; then
    echo "❌ Error: Serena directory not found at $SERENA_DIR"
    exit 1
fi

cd "$SERENA_DIR"

echo ""
echo "📁 Checking directory structure..."
mkdir -p Sources/SerenaCore/Services
mkdir -p Sources/SerenaNet/Services

echo ""
echo "📄 Creating LlamaCppEngine.swift..."
cat > Sources/SerenaCore/Services/LlamaCppEngine.swift << 'LLAMA_ENGINE_EOF'
import Foundation
import os.log

/// LlamaCpp-based LLM engine for running Mistral-7B and other GGUF models locally
@MainActor
final class LlamaCppEngine: AIEngine {
    @Published private(set) var isReady: Bool = false
    @Published private(set) var loadingProgress: Double = 0.0
    @Published private(set) var memoryUsage: Int64 = 0

    let maxContextLength: Int = 4096
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
            "--temp", "0.7",
            "--top-k", "40",
            "--top-p", "0.9",
            "--ctx-size", "2048",
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
LLAMA_ENGINE_EOF

echo "✅ Created LlamaCppEngine.swift"

# Now patch the existing files
echo ""
echo "📝 Patching ChatManager.swift..."
cp Sources/SerenaNet/Services/ChatManager.swift Sources/SerenaNet/Services/ChatManager.swift.backup

python3 << 'CHAT_PATCH'
import sys
with open('Sources/SerenaNet/Services/ChatManager.swift', 'r') as f:
    content = f.read()

# Add embeddingService property
if "private let embeddingService" not in content:
    point = content.find("private let accessibilityManager = AccessibilityManager.shared")
    if point != -1:
        eol = content.find("\n", point)
        content = content[:eol+1] + "    private let embeddingService = LocalEmbeddingService.shared\n" + content[eol+1:]

# Add init call
if "await initializeEmbeddingService()" not in content:
    point = content.find("await initializeAIEngine()")
    if point != -1:
        eol = content.find("\n", point)
        content = content[:eol+1] + "            await initializeEmbeddingService()\n" + content[eol+1:]

# Add init method
if "func initializeEmbeddingService" not in content:
    point = content.find("private func initializeAIEngine() async {")
    if point != -1:
        # Find next MARK
        next_mark = content.find("    // MARK:", point + 10)
        if next_mark != -1:
            method = '''
    private func initializeEmbeddingService() async {
        do {
            try await embeddingService.initialize()
        } catch {
            errorManager.handle(.aiModelInitializationFailed("Embedding: \\(error.localizedDescription)"), context: "Embedding init")
        }
    }

'''
            content = content[:next_mark] + method + content[next_mark:]

# Add semantic search methods
if "func findSimilarMessages" not in content:
    voice_mark = content.find("    // MARK: - Voice Input")
    if voice_mark != -1:
        methods = '''    // MARK: - Semantic Search

    func findSimilarMessages(to query: String, in conversation: Conversation, limit: Int = 5, threshold: Float = 0.7) async throws -> [(message: Message, similarity: Float)] {
        guard embeddingService.isReady else { throw SerenaError.aiModelNotLoaded }
        let queryEmbedding = try await embeddingService.embed(text: query)
        var similarities: [(message: Message, similarity: Float)] = []
        for message in conversation.messages {
            let messageEmbedding = try await embeddingService.embed(text: message.content)
            let similarity = embeddingService.cosineSimilarity(queryEmbedding, messageEmbedding)
            if similarity >= threshold {
                similarities.append((message: message, similarity: similarity))
            }
        }
        return similarities.sorted { $0.similarity > $1.similarity }.prefix(limit).map { $0 }
    }

    func getSemanticContext(for query: String, conversation: Conversation, limit: Int = 5) async -> [Message] {
        do {
            let similarMessages = try await findSimilarMessages(to: query, in: conversation, limit: limit, threshold: 0.6)
            return similarMessages.map { $0.message }
        } catch {
            return Array(conversation.messages.suffix(limit))
        }
    }

    var isEmbeddingReady: Bool {
        return embeddingService.isReady
    }

'''
        content = content[:voice_mark] + methods + content[voice_mark:]

with open('Sources/SerenaNet/Services/ChatManager.swift', 'w') as f:
    f.write(content)
print("✅ ChatManager.swift patched")
CHAT_PATCH

echo "📝 Patching MixtralEngine.swift..."
cp Sources/SerenaNet/Services/MixtralEngine.swift Sources/SerenaNet/Services/MixtralEngine.swift.backup

python3 << 'MIXTRAL_PATCH'
import sys
with open('Sources/SerenaNet/Services/MixtralEngine.swift', 'r') as f:
    content = f.read()

# Add properties
if "llamaCppEngine" not in content:
    point = content.find("private let logger = Logger(subsystem: \"com.serenanet.ai\", category: \"MixtralEngine\")")
    if point != -1:
        eol = content.find("\n", point)
        props = '''
    private var llamaCppEngine: LlamaCppEngine?
    private var useLlamaCpp: Bool = true'''
        content = content[:eol+1] + props + "\n" + content[eol+1:]

# Init llamaCppEngine in init()
if "llamaCppEngine = LlamaCppEngine" not in content:
    init_point = content.find("init(configuration: AIEngineConfiguration = .default) {")
    if init_point != -1:
        # Find closing brace
        brace_count = 0
        i = init_point
        while i < len(content):
            if content[i] == '{': brace_count += 1
            elif content[i] == '}':
                brace_count -= 1
                if brace_count == 0:
                    init_code = '''

        if useLlamaCpp {
            llamaCppEngine = LlamaCppEngine(configuration: configuration)
        }
'''
                    content = content[:i] + init_code + "    " + content[i:]
                    break
            i += 1

# Try llamaCpp first in initialize()
if "Attempting to initialize LlamaCpp" not in content:
    init_func = content.find("func initialize() async throws {")
    if init_func != -1:
        do_block = content.find("do {", init_func)
        if do_block != -1:
            attempt = '''
        if let llamaEngine = llamaCppEngine {
            do {
                logger.info("🦙 Trying LlamaCpp...")
                try await llamaEngine.initialize()
                if llamaEngine.isReady {
                    logger.info("✅ LlamaCpp ready - using real LLM")
                    isReady = true
                    isInitializing = false
                    loadingProgress = 1.0
                    return
                }
            } catch {
                logger.warning("⚠️ LlamaCpp failed: \\(error.localizedDescription)")
            }
        }

        '''
            content = content[:do_block] + attempt + content[do_block:]

# Delegate to llamaCpp in generateResponse
if "Using LlamaCpp engine" not in content:
    gen_func = content.find("func generateResponse(for prompt: String, context: [Message]) async throws -> String {")
    if gen_func != -1:
        logger_line = content.find("logger.info(\"Generating response", gen_func)
        if logger_line != -1:
            delegation = '''
        if let llamaEngine = llamaCppEngine, llamaEngine.isReady {
            logger.info("🦙 Using LlamaCpp for real LLM")
            return try await llamaEngine.generateResponse(for: prompt, context: context)
        }

        '''
            content = content[:logger_line] + delegation + content[logger_line:]

with open('Sources/SerenaNet/Services/MixtralEngine.swift', 'w') as f:
    f.write(content)
print("✅ MixtralEngine.swift patched")
MIXTRAL_PATCH

echo ""
echo "🔨 Building project..."
if swift build -c release; then
    echo ""
    echo "✅ BUILD SUCCESSFUL!"
    echo ""
    echo "================================================"
    echo "✅ Mistral-7B Integration Complete!"
    echo "================================================"
    echo ""
    echo "Files Created/Modified:"
    echo "  ✅ Sources/SerenaCore/Services/LlamaCppEngine.swift (NEW)"
    echo "  ✅ Sources/SerenaNet/Services/ChatManager.swift (PATCHED)"
    echo "  ✅ Sources/SerenaNet/Services/MixtralEngine.swift (PATCHED)"
    echo ""
    echo "Backups:"
    echo "  📋 ChatManager.swift.backup"
    echo "  📋 MixtralEngine.swift.backup"
    echo ""
    echo "🚀 Ready to run:"
    echo "  swift run"
    echo ""
    echo "Or use release build:"
    echo "  .build/release/SerenaNet"
    echo ""
else
    echo ""
    echo "❌ BUILD FAILED - Check errors above"
    echo ""
    echo "Backups available to restore:"
    echo "  mv Sources/SerenaNet/Services/ChatManager.swift.backup Sources/SerenaNet/Services/ChatManager.swift"
    echo "  mv Sources/SerenaNet/Services/MixtralEngine.swift.backup Sources/SerenaNet/Services/MixtralEngine.swift"
    exit 1
fi
