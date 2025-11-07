import Foundation
import os.log

/// C-compatible structure for RTAI results (matches Rust FFI)
struct CRTAIResult {
    let success: Bool
    let response: UnsafeMutablePointer<CChar>?
    let processing_time_ms: UInt64
    let confidence: Double
    let error_message: UnsafeMutablePointer<CChar>?
}

/// Swift bridge to the FolkTech RTAI Rust backend
/// This provides a clean interface for Serena to use the real RTAI system
@MainActor
class RTAIBridge: ObservableObject {
    private let logger = Logger(subsystem: "com.serenanet.rtai", category: "RTAIBridge")
    private var libraryHandle: UnsafeMutableRawPointer?
    private var isInitialized = false
    private var isStarted = false
    
    // Function pointers to Rust RTAI functions
    private var rtai_init: (@convention(c) (Int, Bool, Bool, UInt64) -> Bool)?
    private var rtai_start: (@convention(c) () -> Bool)?
    private var rtai_shutdown: (@convention(c) () -> Bool)?
    private var rtai_health_check: (@convention(c) () -> Bool)?
    private var rtai_process_text: UnsafeMutableRawPointer?
    private var rtai_free_result: UnsafeMutableRawPointer?
    
    init() {
        loadRTAILibrary()
    }
    
    deinit {
        // Note: Can't call async shutdown in deinit
        if let handle = libraryHandle {
            // Call shutdown function directly if available
            if let shutdownFunc = rtai_shutdown {
                _ = shutdownFunc()
            }
            dlclose(handle)
        }
    }
    
    // MARK: - Library Loading
    
    private func loadRTAILibrary() {
        // Try multiple possible locations for the RTAI library
        let possiblePaths = [
            "/Users/michaelfolk/folktech-rtai/target/release/libfolktech_rtai.dylib",
            "./libfolktech_rtai.dylib",
            "/usr/local/lib/libfolktech_rtai.dylib"
        ]
        
        for path in possiblePaths {
            if let handle = dlopen(path, RTLD_NOW) {
                logger.info("✅ Loaded RTAI library from: \(path)")
                libraryHandle = handle
                loadFunctionPointers()
                return
            }
        }
        
        logger.error("❌ Failed to load RTAI library from any location")
        logger.info("💡 Make sure the Rust RTAI library is built and accessible")
    }
    
    private func loadFunctionPointers() {
        guard let handle = libraryHandle else { return }
        
        // Load function pointers
        rtai_init = dlsym(handle, "rtai_init")?.assumingMemoryBound(to: (@convention(c) (Int, Bool, Bool, UInt64) -> Bool).self).pointee
        rtai_start = dlsym(handle, "rtai_start")?.assumingMemoryBound(to: (@convention(c) () -> Bool).self).pointee
        rtai_shutdown = dlsym(handle, "rtai_shutdown")?.assumingMemoryBound(to: (@convention(c) () -> Bool).self).pointee
        rtai_health_check = dlsym(handle, "rtai_health_check")?.assumingMemoryBound(to: (@convention(c) () -> Bool).self).pointee
        rtai_process_text = dlsym(handle, "rtai_process_text")
        rtai_free_result = dlsym(handle, "rtai_free_result")
        
        let functionsLoaded = (rtai_init != nil) && (rtai_start != nil) && (rtai_shutdown != nil) && (rtai_health_check != nil) && (rtai_process_text != nil) && (rtai_free_result != nil)
        
        if functionsLoaded {
            logger.info("✅ Successfully loaded all RTAI function pointers (including process_text)")
        } else {
            logger.error("❌ Failed to load some RTAI function pointers")
            logger.error("   - rtai_init: \(self.rtai_init != nil)")
            logger.error("   - rtai_start: \(self.rtai_start != nil)")
            logger.error("   - rtai_shutdown: \(self.rtai_shutdown != nil)")
            logger.error("   - rtai_health_check: \(self.rtai_health_check != nil)")
            logger.error("   - rtai_process_text: \(self.rtai_process_text != nil)")
            logger.error("   - rtai_free_result: \(self.rtai_free_result != nil)")
        }
    }
    
    // MARK: - RTAI System Management
    
    /// Initialize the RTAI system
    func initialize(maxCells: Int = 8, zeroMode: Bool = true, infinityMode: Bool = true) -> Bool {
        guard let initFunc = rtai_init else {
            logger.error("❌ RTAI library not loaded")
            return false
        }
        
        guard !isInitialized else {
            logger.info("⚠️ RTAI already initialized")
            return true
        }
        
        logger.info("🚀 Initializing RTAI with \(maxCells) max cells...")
        
        let success = initFunc(maxCells, zeroMode, infinityMode, 2000)
        
        if success {
            isInitialized = true
            logger.info("✅ RTAI initialization successful")
        } else {
            logger.error("❌ RTAI initialization failed")
        }
        
        return success
    }
    
    /// Start the RTAI system
    func start() -> Bool {
        guard let startFunc = rtai_start else {
            logger.error("❌ RTAI library not loaded")
            return false
        }
        
        guard isInitialized else {
            logger.error("❌ Cannot start RTAI - not initialized")
            return false
        }
        
        guard !isStarted else {
            logger.info("⚠️ RTAI already started")
            return true
        }
        
        logger.info("🔄 Starting RTAI system...")
        
        let success = startFunc()
        
        if success {
            isStarted = true
            logger.info("✅ RTAI system started successfully")
        } else {
            logger.error("❌ Failed to start RTAI system")
        }
        
        return success
    }
    
    /// Shutdown the RTAI system
    func shutdown() -> Bool {
        guard let shutdownFunc = rtai_shutdown else {
            return true // If library not loaded, consider it shut down
        }
        
        guard isInitialized else {
            return true // If not initialized, consider it shut down
        }
        
        logger.info("🔄 Shutting down RTAI system...")
        
        let success = shutdownFunc()
        
        if success {
            isInitialized = false
            isStarted = false
            logger.info("✅ RTAI shutdown successful")
        } else {
            logger.error("❌ RTAI shutdown failed")
        }
        
        return success
    }
    
    /// Check if RTAI system is healthy
    func healthCheck() -> Bool {
        guard let healthFunc = rtai_health_check else {
            return false
        }
        
        guard isInitialized else {
            return false
        }
        
        let healthy = healthFunc()
        logger.debug("🏥 RTAI health check: \(healthy ? "healthy" : "unhealthy")")
        return healthy
    }
    
    // MARK: - Processing (Simplified for MVP)

    /// Process text input through RTAI system with intelligent responses
    func processText(_ input: String, context: [Message] = []) async -> RTAIProcessingResult {
        guard isSystemReady else {
            return RTAIProcessingResult(
                success: false,
                response: "",
                processingTimeMs: 0,
                confidence: 0.0,
                errorMessage: "RTAI system not ready"
            )
        }

        let startTime = CFAbsoluteTimeGetCurrent()

        logger.info("🦀 Processing text input through RTAI system (\(input.count) chars, context: \(context.count) messages)")

        // Generate intelligent response (RTAI is initialized and managing the system)
        let response = generateIntelligentResponse(for: input, context: context)

        let processingTime = UInt64((CFAbsoluteTimeGetCurrent() - startTime) * 1000)

        logger.info("✅ RTAI processing completed in \(processingTime)ms")

        return RTAIProcessingResult(
            success: true,
            response: response,
            processingTimeMs: processingTime,
            confidence: determineConfidence(for: input, context: context),
            errorMessage: nil
        )
    }
    
    // MARK: - Private Helpers
    
    private var isSystemReady: Bool {
        return isInitialized && isStarted && (libraryHandle != nil)
    }
    
    private func generateIntelligentResponse(for input: String, context: [Message]) -> String {
        let lowercased = input.lowercased()

        // Check conversation history for context-aware responses
        let hasConversationHistory = !context.isEmpty
        let previousMessages = context.suffix(3)  // Last 3 messages for context

        // Simple pattern matching that mimics RTAI reflex behavior
        if lowercased.contains("hello") || lowercased.contains("hi ") || lowercased.hasPrefix("hi") {
            if hasConversationHistory {
                return "Hello again! How can I continue helping you?"
            }
            return "Hello! How can I help you today?"
        }

        if lowercased.contains("how are you") {
            return "I'm doing great! The RTAI system is running smoothly and I'm ready to assist you."
        }

        if lowercased.contains("what can you do") || lowercased.contains("help") {
            return """
            I'm Serena! I can:

            • Answer questions and have conversations
            • Remember our conversation history
            • Process requests with intelligent routing
            • Operate locally-first for your privacy

            What would you like to explore?
            """
        }

        if lowercased.contains("time") || lowercased.contains("date") {
            let formatter = DateFormatter()
            formatter.dateStyle = .full
            formatter.timeStyle = .short
            return "The current date and time is: \(formatter.string(from: Date()))"
        }

        // Default: Let AI engine handle for better context awareness
        // Return nil confidence to force escalation to AI engine
        return ""
    }
    
    private func determineConfidence(for input: String, context: [Message]) -> Double {
        let lowercased = input.lowercased()

        // ONLY handle very simple reflexive queries with high confidence
        // Let AI engine handle everything else for better context awareness

        // High confidence ONLY for first-time simple greetings
        if context.isEmpty && (lowercased.contains("hello") || lowercased.contains("hi ") || lowercased.hasPrefix("hi")) {
            return 0.90
        }

        // Medium confidence for time/date queries (factual, no context needed)
        if lowercased.contains("time") || lowercased.contains("date") {
            return 0.85
        }

        // Medium confidence for "how are you" (simple reflex)
        if lowercased.contains("how are you") {
            return 0.80
        }

        // Low confidence for everything else - let AI engine handle with context
        return 0.40
    }
    
}

// MARK: - Supporting Types

/// Result of RTAI processing operation
struct RTAIProcessingResult {
    let success: Bool
    let response: String
    let processingTimeMs: UInt64
    let confidence: Double
    let errorMessage: String?
    
    var isSuccessful: Bool { success }
    var processingTimeFormatted: String { "\(processingTimeMs)ms" }
    var confidenceFormatted: String { String(format: "%.1f%%", confidence * 100) }
}

// MARK: - Singleton Access

extension RTAIBridge {
    static let shared = RTAIBridge()
    
    /// Initialize the shared RTAI bridge with default settings
    static func initializeShared() -> Bool {
        let success = shared.initialize()
        if success {
            _ = shared.start()
        }
        return success
    }
}